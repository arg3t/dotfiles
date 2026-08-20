package refs

import (
	"regexp"
	"strings"
	"time"

	"github.com/arg3t/dotfiles/herdr-workstreams/internal/model"
)

var (
	jiraRE = regexp.MustCompile(`\b([A-Z][A-Z0-9]+-[0-9]+)\b`)
	prRE   = regexp.MustCompile(`https?://github\.com/[^/\s]+/[^/\s]+/pull/([0-9]+)\b`)
	urlRE  = regexp.MustCompile(`https?://[^\s<>()\[\]{}]+`)
)

func Extract(text string) []model.Reference {
	seen := map[string]bool{}
	out := []model.Reference{}
	add := func(ref model.Reference) {
		if ref.ID == "" || seen[ref.Key()] {
			return
		}
		seen[ref.Key()] = true
		out = append(out, ref)
	}
	for _, key := range jiraRE.FindAllStringSubmatch(text, -1) {
		add(model.Reference{Kind: model.ReferenceJira, ID: strings.ToUpper(key[1]), Discovered: time.Now().UTC()})
	}
	for _, match := range prRE.FindAllStringSubmatch(text, -1) {
		add(model.Reference{Kind: model.ReferencePR, ID: match[1], URL: match[0], Discovered: time.Now().UTC()})
	}
	for _, url := range urlRE.FindAllString(text, -1) {
		add(model.Reference{Kind: model.ReferenceURL, ID: url, URL: url, Discovered: time.Now().UTC()})
	}
	return out
}
