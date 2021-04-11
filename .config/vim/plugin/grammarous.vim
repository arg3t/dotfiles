let g:languagetool_cmd='/usr/bin/languagetool'
let g:grammarous#default_comments_only_filetypes = {
            \ '*' : 1, 'help' : 0, 'markdown' : 0, 'tex': 0,
            \ }

let g:grammarous#enabled_categories = {'tex' : ['PUNCTUATION',
      \'COLLOQUIALISMS', 'COMPOUNDING', 'CONFUSED_WORDS', 'FALSE_FRIENDS',
      \ 'GENDER_NEUTRALITY', 'GRAMMAR', 'MISC', 'PLAIN_ENGLISH',
      \ 'PUNCTUATION', 'REDUNDANCY', 'REGIONALISMS', 'REPETITIONS',
      \ 'SEMANTICS', 'STYLE', 'TYPOGRAPHY',
      \ 'TYPOS', 'WIKIPEDIA'], 'markdown' : ['PUNCTUATION',
      \'COLLOQUIALISMS', 'COMPOUNDING', 'CONFUSED_WORDS', 'FALSE_FRIENDS',
      \ 'GENDER_NEUTRALITY', 'GRAMMAR', 'MISC', 'PLAIN_ENGLISH',
      \ 'PUNCTUATION', 'REDUNDANCY', 'REGIONALISMS', 'REPETITIONS',
      \ 'SEMANTICS', 'STYLE', 'TYPOGRAPHY',]}
