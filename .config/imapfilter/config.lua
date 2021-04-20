-- According to the IMAP specification, when trying to write a message
-- to a non-existent mailbox, the server must send a hint to the client,
-- whether it should create the mailbox and try again or not. However
-- some IMAP servers don't follow the specification and don't send the
-- correct response code to the client. By enabling this option the
-- client tries to create the mailbox, despite of the server's response.
-- This variable takes a boolean as a value.  Default is “false”.
options.create = true
-- By enabling this option new mailboxes that were automatically created,
-- get auto subscribed
options.subscribe = true
-- How long to wait for servers response.
options.timeout = 120

function trim(s)
   return (s:gsub("^%s*(.-)%s*$", "%1"))
end

-- Gets password from pass
status, dom_password = pipe_from('pass show Email/privateemail.com/yigit@yigitcolakoglu.com')
domain = IMAP {
  server = "mail.privateemail.com",
  port = 143,
  username = "yigit@yigitcolakoglu.com",
  password = trim(dom_password ),
  ssl = auto
}

-- Gets password from pass
status, hot_password = pipe_from('pass show AppPass/microsoft.com/yigitcolakoglu@hotmail.com')
-- Setup an imap account called hotmail
hotmail = IMAP {
  server = "outlook.office365.com",
  port = 143,
  username = "yigitcolakoglu@hotmail.com",
  password = trim(hot_password),
  ssl = auto
}

-- Block fucking Aleksandr. LEAVE ME ALONE DUDE

function fuckAleksandr()
  mailboxes, folders = domain:list_all("/")
  for _, v in pairs(mailboxes) do
    messages = domain[v]:contain_subject("Предложение")
    messages:delete_messages()
  end
end

print("Fuck Aleksandr")
fuckAleksandr {}
print("Done fucking Aleksandr")
