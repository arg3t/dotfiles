package refs

import "testing"

func TestExtractDeduplicatesTicketPRAndURL(t *testing.T) {
	items := Extract("ES-1234 https://github.com/acme/shop/pull/42 and ES-1234 https://github.com/acme/shop/pull/42")
	if len(items) != 3 {
		t.Fatalf("Extract() got %d references, want 3", len(items))
	}
	if items[0].ID != "ES-1234" {
		t.Fatalf("first ref = %q, want ES-1234", items[0].ID)
	}
	if items[1].ID != "42" {
		t.Fatalf("second ref = %q, want PR number 42", items[1].ID)
	}
}
