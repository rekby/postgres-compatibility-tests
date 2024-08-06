/*
Copyright © 2024 NAME HERE <EMAIL ADDRESS>
*/
package cmd

import (
	"compress/gzip"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"log"
	"math"
	"os"
	"regexp"
	"slices"
	"strings"
	"sync"
	"sync/atomic"
	"time"

	"github.com/spf13/cobra"
	"github.com/ydb-platform/ydb-go-sdk/v3"
	"github.com/ydb-platform/ydb-go-sdk/v3/query"
	"gopkg.in/yaml.v3"

	"github.com/ydb-platform/postgres-compatibility-tests/tools/greenplum-to-pg-tests/internal"
)

var checkPgQueriesConfig struct {
	schemeDumpFile            string
	sessionsLog               string
	sessionsLogNeedSort       bool
	includeFailed             bool
	ydbConnectionString       string
	limitRequests             int
	rulesFile                 string
	writeRulesWithStat        string
	sortRulesByCount          bool
	printKnownIssues          bool
	printQueryForKnownIssue   bool
	printErrorsInProgress     bool
	printStats                bool
	printProgressEveryQueries int
	writeStatPath             string
	writeStatEveryItems       int
	checkersCount             int
}

func init() {
	rootCmd.AddCommand(checkPgQueriesCmd)

	checkPgQueriesCmd.PersistentFlags().StringVar(&checkPgQueriesConfig.schemeDumpFile, "schemedump-file", "", "Path to dump of db schema. Set empty for skip read schema.")
	checkPgQueriesCmd.PersistentFlags().StringVar(&checkPgQueriesConfig.sessionsLog, "query-log", "", "Set path to input sessions log")
	checkPgQueriesCmd.PersistentFlags().BoolVar(&checkPgQueriesConfig.sessionsLogNeedSort, "query-log-need-sort", false, "Sort query log in memory before start")
	must0(checkPgQueriesCmd.MarkPersistentFlagRequired("query-log"))

	checkPgQueriesCmd.PersistentFlags().BoolVar(&checkPgQueriesConfig.includeFailed, "include-failed", true, "Extract sessions with failed transactions")
	checkPgQueriesCmd.PersistentFlags().StringVar(&checkPgQueriesConfig.ydbConnectionString, "ydb-connection", "grpc://localhost:2136/local", "Connection string to ydb server for check queries")
	checkPgQueriesCmd.PersistentFlags().IntVar(&checkPgQueriesConfig.limitRequests, "requests-limit", 0, "Limit number of parse requests, 0 mean unlimited")
	checkPgQueriesCmd.PersistentFlags().StringVar(&checkPgQueriesConfig.rulesFile, "rules-file", "issues.yaml", "Rules for detect issue. Set empty for skip read rules.")
	checkPgQueriesCmd.PersistentFlags().StringVar(&checkPgQueriesConfig.writeRulesWithStat, "write-updated-rules", "issues_stat.yaml", "Write rules with updated stats, may be same or other file as for rules-file")
	checkPgQueriesCmd.PersistentFlags().BoolVar(&checkPgQueriesConfig.sortRulesByCount, "sort-updates-rules-by-count", true, "")
	checkPgQueriesCmd.PersistentFlags().BoolVar(&checkPgQueriesConfig.printKnownIssues, "print-known-issues", false, "Print known issues instead of unknown")
	checkPgQueriesCmd.PersistentFlags().BoolVar(&checkPgQueriesConfig.printQueryForKnownIssue, "print-query-for-known-issues", true, "Print query for known issues")
	checkPgQueriesCmd.PersistentFlags().BoolVar(&checkPgQueriesConfig.printErrorsInProgress, "print-progress", false, "Print queries in progress")
	checkPgQueriesCmd.PersistentFlags().BoolVar(&checkPgQueriesConfig.printStats, "print-stats", true, "Print queries in progress")
	checkPgQueriesCmd.PersistentFlags().IntVar(&checkPgQueriesConfig.printProgressEveryQueries, "print-progress-every-queries", 100, "Periodically print progress")
	checkPgQueriesCmd.PersistentFlags().StringVar(&checkPgQueriesConfig.writeStatPath, "write-stat-file", "", "Path to write full stat file if need. Will write example of queries")
	checkPgQueriesCmd.PersistentFlags().IntVar(&checkPgQueriesConfig.writeStatEveryItems, "write-stat-every-items", 10000, "Interval for write current stat")

	checkPgQueriesCmd.PersistentFlags().IntVar(&checkPgQueriesConfig.checkersCount, "check-queries-parallel", 5, "How many queries may be checked in parallel")
}

// extraxtSessionsCmd represents the extraxtSessions command
var checkPgQueriesCmd = &cobra.Command{
	Use:   "check-pg-queries",
	Short: "Read session queryies log end extract sessions to files",
	Run: func(cmd *cobra.Command, args []string) {
		ctx := context.Background()

		var rules Rules
		if checkPgQueriesConfig.rulesFile == "" {
			log.Println("Skip read rules file.")
		} else {
			log.Printf("Reading rules file %q...", checkPgQueriesConfig.rulesFile)
			if err := rules.LoadFromFile(checkPgQueriesConfig.rulesFile); err != nil {
				log.Fatalf("Failed to read rules file: %v", err)
			}
		}

		schema := internal.NewPgSchema()
		if checkPgQueriesConfig.schemeDumpFile == "" {
			log.Println("Skip read session")
		} else {
			log.Println("Reading schema.. ")
			schemaFile, err := os.Open(checkPgQueriesConfig.schemeDumpFile)
			if err != nil {
				log.Fatalf("Failed to open scheme file")
			}

			schema.Read(schemaFile)
			_ = schemaFile.Close()
		}

		log.Println("Connecting to ydb...")
		connectCtx, cancel := context.WithTimeout(ctx, time.Second*10)
		connectionStrings := strings.Split(checkPgQueriesConfig.ydbConnectionString, ",")
		dbPool := internal.OpenYdbPool(connectCtx, connectionStrings, []ydb.Option{internal.GetYdbCredentials()})
		cancel()

		var queries <-chan string
		fileReader := openFileReader()
		if checkPgQueriesConfig.sessionsLogNeedSort {
			queries = generateQueriesFromUnsortedSessions(fileReader)
		} else {
			queries = readSortedQueries(fileReader)
		}

		log.Println("Start check queries")
		var stats QueryStats
		checkQueries(rules, &stats, dbPool, queries)

		if checkPgQueriesConfig.writeRulesWithStat != "" {
			rules.UpdateFromStats(&stats, checkPgQueriesConfig.sortRulesByCount)
			if err := rules.WriteToFile(checkPgQueriesConfig.writeRulesWithStat); err != nil {
				log.Printf("Failed to update rules stat: %v", err)
			}
		}

		if checkPgQueriesConfig.writeStatPath != "" {
			if err := stats.SaveToFile(checkPgQueriesConfig.writeStatPath); err != nil {
				log.Printf("Failed to save stat file %q: %v", checkPgQueriesConfig.writeStatPath, err)
			}
		}
	},
}

func openFileReader() io.ReadCloser {
	filepath := checkPgQueriesConfig.sessionsLog
	fileReader, err := os.Open(filepath)
	if err != nil {
		log.Fatalf("Failed to open file %q: %v", filepath, err)
	}

	if strings.HasSuffix(strings.ToLower(filepath), ".gz") {
		gzipReader, err := gzip.NewReader(fileReader)
		if err != nil {
			log.Fatalf("Failed to start gzip reader for %q: %v", filepath, err)
		}
		return gzipReaderClose{
			gzipReader: gzipReader,
			fileReader: fileReader,
		}
	}

	return fileReader
}

type gzipReaderClose struct {
	gzipReader *gzip.Reader
	fileReader *os.File
}

func (g gzipReaderClose) Read(p []byte) (n int, err error) {
	return g.gzipReader.Read(p)
}

func (g gzipReaderClose) Close() error {
	gzipCloseErr := g.gzipReader.Close()
	fileCloseErr := g.fileReader.Close()

	if gzipCloseErr != nil {
		return gzipCloseErr
	}

	return fileCloseErr
}

func readSortedQueries(reader io.ReadCloser) <-chan string {
	queries := make(chan string)
	go func() {
		defer reader.Close()
		defer close(queries)

		decoder := json.NewDecoder(reader)
		limitCount := checkPgQueriesConfig.limitRequests
		counter := 0

		needDeleteLine := false
		for {
			if limitCount > 0 && counter >= limitCount {
				log.Println("Count limit reached")
				return
			}

			var item internal.SessionLogRecord
			if err := decoder.Decode(&item); err != nil {
				switch {
				case errors.Is(err, io.EOF):
					log.Printf("Read file completed, read items: %v", counter)
					return
				case err != nil:
					log.Printf("Failed to decode item %v: %v", counter, err)
					return
				default:
					// pass
				}
			}
			if !item.TransactionSuccess && !checkPgQueriesConfig.includeFailed {
				continue
			}

			queries <- item.Query
			counter++
			if counter%checkPgQueriesConfig.printProgressEveryQueries == 0 {
				if needDeleteLine {
					printDeleteLine()
				} else {
					needDeleteLine = true
				}

				var percent float64
				if limitCount > 0 {
					percent = float64(counter) / float64(limitCount) * 100
				}
				log.Printf("Read items %v/%v (%0.2f)", counter, limitCount, percent)
			}
		}
	}()

	return queries
}

func generateQueriesFromUnsortedSessions(reader io.ReadCloser) <-chan string {
	sessions := readSessions(reader)
	return extractQueries(sessions)
}

func readSessions(reader io.ReadCloser) []internal.Session {
	defer reader.Close()

	decoder := json.NewDecoder(reader)

	sortedLogs := map[int]map[int]map[int]map[int]internal.SessionLogRecord{} // pid/session/transaction/query

	limitCount := checkPgQueriesConfig.limitRequests

	counter := 0

	log.Println("Start reading file...")
readLoop:
	for {
		if limitCount > 0 && counter >= limitCount {
			log.Println("Reached limit for parse request count:", limitCount)
			break
		}

		counter++
		if counter%1000 == 0 {
			print(".")
		}
		var entry internal.SessionLogRecord
		err := decoder.Decode(&entry)
		if errors.Is(err, io.EOF) {
			break readLoop
		}
		if errors.Is(err, io.ErrUnexpectedEOF) {
			log.Println("Unexpected EOF")
			break readLoop
		}
		if err != nil {
			log.Printf("failed to parse line: %v\n", err)
			continue readLoop
		}

		if sortedLogs[entry.ProcessID] == nil {
			sortedLogs[entry.ProcessID] = make(map[int]map[int]map[int]internal.SessionLogRecord)
		}
		if sortedLogs[entry.ProcessID][entry.SessionID] == nil {
			sortedLogs[entry.ProcessID][entry.SessionID] = make(map[int]map[int]internal.SessionLogRecord)
		}
		if sortedLogs[entry.ProcessID][entry.SessionID][entry.TransactionCount] == nil {
			sortedLogs[entry.ProcessID][entry.SessionID][entry.TransactionCount] = make(map[int]internal.SessionLogRecord)
		}
		if _, exists := sortedLogs[entry.ProcessID][entry.SessionID][entry.TransactionCount][entry.QueryCount]; exists {
			log.Printf("duplicated record: %v/%v/%v\n", entry.SessionID, entry.TransactionCount, entry.QueryCount)
			continue readLoop
		}

		sortedLogs[entry.ProcessID][entry.SessionID][entry.TransactionCount][entry.QueryCount] = entry
	}

	log.Println("Scanned entries:", len(sortedLogs))
	log.Println("Sort by sessions")

	var res []internal.Session

	pids := internal.GetSortedKeys(sortedLogs)
	for _, pid := range pids {
		sessionIDs := internal.GetSortedKeys(sortedLogs[pid])
		for _, sessionID := range sessionIDs {
			var session internal.Session
			session.ID = fmt.Sprintf("%v-%v", pid, sessionID)

			transactionNums := internal.GetSortedKeys(sortedLogs[pid][sessionID])
			for _, transactionNum := range transactionNums {
				transaction := internal.Transaction{
					Number: transactionNum,
				}

				queryIDs := internal.GetSortedKeys(sortedLogs[pid][sessionID][transactionNum])
				for _, queryID := range queryIDs {
					entry := sortedLogs[pid][sessionID][transactionNum][queryID]
					transaction.Queries = append(transaction.Queries, internal.Query{
						Number: entry.QueryCount,
						Text:   entry.Query,
					})
					if !entry.TransactionSuccess {
						transaction.Success = false
					}
				}
				session.Transactions = append(session.Transactions, transaction)
			}

			res = append(res, session)
		}
	}

	return res
}

func extractQueries(sessions []internal.Session) <-chan string {
	queries := make(chan string)

	go func() {
		totalQueries := 0
		for _, session := range sessions {
			for _, transaction := range session.Transactions {
				totalQueries += len(transaction.Queries)
			}
		}

		queryIndex := 0
		needRemoveLine := false
		for _, session := range sessions {
			for _, transaction := range session.Transactions {
				if !transaction.Success && !checkPgQueriesConfig.includeFailed {
					continue
				}

				for _, pgQuery := range transaction.Queries {
					queryIndex++
					if queryIndex%checkPgQueriesConfig.printProgressEveryQueries == 0 {
						percent := float64(queryIndex) / float64(totalQueries) * 100
						if needRemoveLine {
							printDeleteLine()
						} else {
							needRemoveLine = true
						}
						log.Printf("Checking query %8d/%v (%0.2f)", queryIndex, totalQueries, percent)
					}
					queries <- pgQuery.Text
				}
			}
		}

		close(queries)
	}()

	return queries
}

func printDeleteLine() {
	fmt.Printf("\033[1A\033[K")
}

func checkQueries(rules Rules, stats *QueryStats, dbPool *internal.YdbPool, queries <-chan string) {
	if checkPgQueriesConfig.checkersCount < 1 {
		log.Fatalf("can't start less then 1 checker, got: %v", checkPgQueriesConfig.checkersCount)
	}

	var itemsCounter atomic.Int64
	writeStatEveryItems := int64(checkPgQueriesConfig.writeStatEveryItems)
	var wg sync.WaitGroup
	var writeStatMutex sync.Mutex
	for range checkPgQueriesConfig.checkersCount {
		wg.Add(1)
		go func() {
			defer wg.Done()
			for q := range queries {
				checkQuery(stats, rules, dbPool, q)
				counter := itemsCounter.Add(1)
				if writeStatEveryItems > 0 && counter%writeStatEveryItems == 0 {
					writeStatMutex.Lock()
					if checkPgQueriesConfig.writeStatPath != "" {
						if err := stats.SaveToFile(checkPgQueriesConfig.writeStatPath); err != nil {
							log.Printf("Stat file written failed %q: %v", checkPgQueriesConfig.writeStatPath, err)
						}
					}
					if checkPgQueriesConfig.writeRulesWithStat != "" {
						rules.UpdateFromStats(stats, checkPgQueriesConfig.sortRulesByCount)
						if err := rules.WriteToFile(checkPgQueriesConfig.writeRulesWithStat); err != nil {
							log.Printf("Failed to update rules stat: %v", err)
						}
					}
					writeStatMutex.Unlock()
				}
			}
		}()
	}
	wg.Wait()
}

type checkResultType int

const (
	checkResultOK checkResultType = iota
	checkResultErrKnown
	checkResultErrUnknown
)

func checkQuery(stat *QueryStats, rules Rules, dbPool *internal.YdbPool, queryText string) (reason string, checkResult checkResultType) {
	db := dbPool.Get()
	defer dbPool.Release(db)

	queryText = strings.TrimSpace(queryText)
	queryText = fixSchemaNames(queryText)
	queryText = fixCreateTable(queryText)
	queryText = cutUnsupportedConstructions(queryText)

	ctx := context.Background()
	res, err := db.Query().Execute(
		ctx,
		queryText,
		query.WithExecMode(query.ExecModeExplain),
		query.WithSyntax(query.SyntaxPostgreSQL),
	)
	if res != nil {
		_ = res.Close(ctx)
	}

	if err == nil {
		stat.CountASOK(queryText)
		return "", checkResultOK
	}

	var ydbErr ydb.Error
	errors.As(err, &ydbErr)

	issues := internal.ExtractIssues(err)

	knownIssues, unknownIssues := rules.MatchToKnownIssues(queryText, issues)
	for _, knownIssue := range knownIssues {
		if knownIssue.Name != "" && !knownIssue.Skip {
			stat.CountAsKnown(knownIssue.Name, queryText)
			return knownIssue.Name, checkResultErrKnown
		}
	}

	if ydbErr == nil {
		reason = fmt.Sprintf("non ydb err: %v", err)
	} else {
		reason = fmt.Sprintf("%v (%v): %#v", ydbErr.Name(), ydbErr.Code(), unknownIssues)

	}
	stat.CountAsUnknown(reason, queryText)
	return reason, checkResultErrUnknown
}

type ReplacePair struct {
	From string
	To   string
}

var schemaTableRegexp = regexp.MustCompile(`(?i)(CREATE TABLE|FROM|INSERT INTO|JOIN|UPDATE)\s+"?([^\s."]+)"?\."?([^\s."]+)"?`)

func fixSchemaNames(queryText string) string {
	queryText = schemaTableRegexp.ReplaceAllString(queryText, "${1} ${2}___${3}")
	return queryText
}

var createTableRegexp = regexp.MustCompile(`^(?i)(CREATE TABLE.*\()`)

func fixCreateTable(queryText string) string {
	if !strings.Contains(queryText, "CREATE TABLE") {
		return queryText
	}

	queryText = createTableRegexp.ReplaceAllString(queryText, "$1 __stub_primary_key SERIAL PRIMARY KEY,")
	return queryText
}

func cutUnsupportedConstructions(q string) string {
	q = createAS.ReplaceAllString(q, "$1")
	q = createTableAsSelect.ReplaceAllLiteralString(q, "SELECT")
	q = distributedBy.ReplaceAllLiteralString(q, "")
	q = distributedWord.ReplaceAllLiteralString(q, "")
	return q
}

var (
	createAS            = regexp.MustCompile(`(?is)CREATE\s+.*\sTABLE\s+.*\s+AS\s+\(\s*(.*)\s*\)\s`)
	createTableAsSelect = regexp.MustCompile(`(?is)CREATE\s+(TEMPORARY\s+)?TABLE .* AS\s+SELECT`)
	distributedBy       = regexp.MustCompile(`(?is)DISTRIBUTED BY \(.*\)`)
	distributedWord     = regexp.MustCompile(`(?is)DISTRIBUTED \w+`)
)

type QueryStats struct {
	m              sync.RWMutex
	writeStatMutex sync.Mutex

	okCount    int
	totalCount int

	MatchToRules    map[string]*CounterWithExample[string] // [rule name] query example
	UnknownProblems map[string]*CounterWithExample[string]
}

func (s *QueryStats) GetTotalCount() int {
	s.m.Lock()
	defer s.m.Unlock()

	return s.totalCount
}

func (s *QueryStats) GetOkCount() int {
	s.m.Lock()
	defer s.m.Unlock()

	return s.okCount
}

func (s *QueryStats) GetOkPercent() float64 {
	s.m.RLock()
	defer s.m.RUnlock()

	return s.getOkPercentNeedLock()
}

func (s *QueryStats) getOkPercentNeedLock() float64 {
	return float64(s.okCount) / float64(s.totalCount) * 100
}

func (s *QueryStats) CountASOK(query string) {
	s.m.Lock()
	defer s.m.Unlock()

	s.totalCount++
	s.okCount++
}

func (s *QueryStats) CountAsKnown(ruleName string, query string) {
	s.m.Lock()
	defer s.m.Unlock()

	s.totalCount++
	if s.MatchToRules == nil {
		s.MatchToRules = make(map[string]*CounterWithExample[string])
	}

	var stat *CounterWithExample[string]
	var ok bool
	if stat, ok = s.MatchToRules[ruleName]; !ok {
		stat = &CounterWithExample[string]{
			ID:      ruleName,
			Example: query,
		}
		s.MatchToRules[ruleName] = stat
	}

	stat.Count++
	if len(query) < len(stat.Example) {
		stat.Example = query
	}
}

func (s *QueryStats) CountAsUnknown(reason string, query string) {
	s.m.Lock()
	defer s.m.Unlock()

	s.totalCount++
	if s.UnknownProblems == nil {
		s.UnknownProblems = make(map[string]*CounterWithExample[string])
	}

	var stat *CounterWithExample[string]
	var ok bool
	if stat, ok = s.UnknownProblems[reason]; !ok {
		stat = &CounterWithExample[string]{
			ID:      reason,
			Example: query,
		}
		s.UnknownProblems[reason] = stat
	}
	stat.Count++
	if len(query) < len(stat.Example) {
		stat.Example = query
	}
}

func (s *QueryStats) GetTopKnown(count int) []CounterWithExample[string] {
	s.m.RLock()
	defer s.m.RUnlock()

	return s.getTopKnownNeedLock(count)
}

func (s *QueryStats) getTopKnownNeedLock(count int) []CounterWithExample[string] {
	return getTopCounter(s.MatchToRules, count)
}

func (s *QueryStats) GetTopUnknown(count int) []CounterWithExample[string] {
	s.m.RLock()
	defer s.m.RUnlock()

	return s.getTopUnknownNeedLock(count)
}

func (s *QueryStats) getTopUnknownNeedLock(count int) []CounterWithExample[string] {
	return getTopCounter(s.UnknownProblems, count)
}

func (s *QueryStats) PrintStats() {
	s.m.Lock()
	defer s.m.Unlock()

	fmt.Println("Queries stat.")
	fmt.Println("Ok Count:", s.okCount)
	fmt.Println()
	fmt.Println("Known issues")
	SessionStats_printExampleCounter(getTopCounter(s.MatchToRules, 10))

	fmt.Println("New issues")
	SessionStats_printExampleCounter(getTopCounter(s.UnknownProblems, 10))
}

func SessionStats_printExampleCounter[K comparable](examples []CounterWithExample[K]) {
	for _, example := range examples {
		fmt.Printf(`
Problem: %v
Count: %v
Example: %v

`, example.ID, example.Count, example.Example)
	}
}

type CounterWithExample[K comparable] struct {
	ID      K      `yaml:"id"`
	Count   int    `yaml:"count"`
	Example string `yaml:"example"`
}

func getTopCounter[K comparable](m map[K]*CounterWithExample[K], count int) []CounterWithExample[K] {
	res := make([]CounterWithExample[K], 0, len(m))
	for _, stat := range m {
		res = append(res, *stat)
	}

	// Max counts
	slices.SortFunc(res, func(a, b CounterWithExample[K]) int {
		return b.Count - a.Count
	})

	if count >= len(res) {
		return res
	}

	return res[:count]
}

func (s *QueryStats) SaveToFile(path string) error {
	s.writeStatMutex.Lock()
	defer s.writeStatMutex.Unlock()

	s.m.RLock()
	defer s.m.RUnlock()

	var statFile struct {
		TotalCount    int                          `yaml:"total_count"`
		OkCount       int                          `yaml:"ok_count"`
		OkPercent     float64                      `yaml:"ok_percent"`
		UnknownIssues []CounterWithExample[string] `yaml:"unknown_issues"`
		KnownIssues   []CounterWithExample[string] `yaml:"known_issues"`
	}

	statFile.TotalCount = s.totalCount
	statFile.OkCount = s.okCount
	statFile.OkPercent = s.getOkPercentNeedLock()
	statFile.UnknownIssues = s.getTopUnknownNeedLock(math.MaxInt)
	statFile.KnownIssues = s.getTopKnownNeedLock(math.MaxInt)

	for i := range statFile.UnknownIssues {
		statFile.UnknownIssues[i].Example = cleanStringForLiteralYaml(statFile.UnknownIssues[i].Example)
	}
	for i := range statFile.KnownIssues {
		statFile.KnownIssues[i].Example = cleanStringForLiteralYaml(statFile.KnownIssues[i].Example)
	}

	f, err := os.Create(path)
	if err != nil {
		return fmt.Errorf("failed to create file for write stat: %w", err)
	}
	defer f.Close()
	encoder := yaml.NewEncoder(f)
	if err = encoder.Encode(&statFile); err != nil {
		return fmt.Errorf("failed to write stat: %w", err)
	}
	return nil
}

func cleanStringForLiteralYaml(s string) string {
	lines := strings.Split(s, "\n")
	for i, line := range lines {
		// trim ending space
		for strings.HasSuffix(line, " ") {
			line = strings.TrimSuffix(line, " ")
		}
		lines[i] = line
	}

	s = strings.Join(lines, "\n")

	sBytes := []byte(s)
	buf := &strings.Builder{}

	// range over runes
	for i, r := range s {
		if isYamlPrintable(sBytes, i) {
			buf.WriteRune(r)
		} else {
			buf.WriteByte('X')
		}
	}

	return buf.String()
}

func isYamlPrintable(b []byte, i int) bool {
	// copy of yaml.is_printable
	return ((b[i] == 0x0A) || // . == #x0A
		(b[i] >= 0x20 && b[i] <= 0x7E) || // #x20 <= . <= #x7E
		(b[i] == 0xC2 && b[i+1] >= 0xA0) || // #0xA0 <= . <= #xD7FF
		(b[i] > 0xC2 && b[i] < 0xED) ||
		(b[i] == 0xED && b[i+1] < 0xA0) ||
		(b[i] == 0xEE) ||
		(b[i] == 0xEF && // #xE000 <= . <= #xFFFD
			!(b[i+1] == 0xBB && b[i+2] == 0xBF) && // && . != #xFEFF
			!(b[i+1] == 0xBF && (b[i+2] == 0xBE || b[i+2] == 0xBF))))
}
