# Load our dependencies and configuration settings
$LOAD_PATH.push(File.expand_path(File.dirname(__FILE__)))
require 'evernote_config.rb'
require 'viewsnet_config.rb'

#
# download invoice pdf file
#
def download_invoice_viewsnet(year=nil, month=nil)
  # Get the agent instance
  agent = Mechanize.new

  download_url = ""
  agent.get(VIEWSNET_LOGIN_URL) do |login_page|
    v0100_004_page = login_page.form_with(:method => "POST") do |login|
      login.field_with(:name => "id").value = VIEWSNET_USER # login id for VIEW's NET
      login.field_with(:name => "pass").value = VIEWSNET_PASS # login password for VIEW's NET
    end.submit

    v0300_001_page = v0100_004_page.link_with(:id => "LnkV0300_001Top").click

    v0300_002_page = v0300_001_page.form_with(:name => "Frm002") do |form|
      form.add_field!("__EVENTTARGET", "LnkClaimYm1")
      form.add_field!("__EVENTARGUMENT", "")
    end.submit

    pdf_button = ""
    v0300_002_form = v0300_002_page.form_with(:name => "Form1") do |form|
      pdf_button = form.button_with(:name => "BtnPdfDownloadTop")
    end

    response = agent.submit(v0300_002_form, pdf_button)
    onload = response.search("body").attr("onload").value
    download_url = onload.split("location.href=")[1].delete('\';}}')
  end

  # year and month for download invoice
  year = Time.now.strftime("%Y") if year.nil?
  month = Time.now.strftime("%m") if month.nil?

  # File open for write and binary mode
  pdf_file = File.open("#{year}#{month}.pdf",'wb')

  # Start download and create invoice pdf
  pdf_file.puts agent.get_file(download_url)

  # File close
  pdf_file.close

  # Return created file object
  pdf_file
end

#
# make evernote
#
def put_note(note_title, note_body, parent_notebook_guid=nil, resources=[], tags=[])

  # Create note object
  our_note = Evernote::EDAM::Type::Note.new
  our_note.title = note_title

  # Create note body
  n_body = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
  n_body += "<!DOCTYPE en-note SYSTEM \"http://xml.evernote.com/pub/enml2.dtd\">"
  n_body += "<en-note>#{note_body}"

  # Resources is optional; if omitted, resource is nothing
  unless resources.empty?
    # Add Resource objects to note body
    n_body += "<br /><br />"
    our_note.resources = resources
    resources.each do |resource|
      hash_func = Digest::MD5.new
      hexhash = hash_func.hexdigest(resource.data.body)
      n_body += "<en-media type=\"#{resource.mime}\" hash=\"#{hexhash}\" /><br />"
    end
  end

  n_body += "</en-note>"

  our_note.content = n_body

  # parentNotebook is optional; if omitted, default notebook is used
  our_note.notebookGuid = parent_notebook_guid unless parent_notebook_guid.nil?

  # Set note author
  our_note.attributes = Evernote::EDAM::Type::NoteAttributes.new
  our_note.attributes.author = NOTE_AUTHOR

  # Note tag is optional; if omitted, tag is nothing
  our_note.tagNames = tags unless tags.empty?

  # Set up the NoteStore client
  client = EvernoteOAuth::Client.new(
    token: DEVELOPER_TOKEN,
    sandbox: SANDBOX
  )
  note_store = client.note_store

  # Attempt to create note in Evernote account
  begin
    note = note_store.createNote(our_note)
  rescue Evernote::EDAM::Error::EDAMUserException => edue
    # Something was wrong with the note data
    # See EDAMErrorCode enumeration for error code explanation
    # http://dev.evernote.com/documentation/reference/Errors.html#Enum_EDAMErrorCode
    puts "EDAMUserException: #{edue}"
  rescue Evernote::EDAM::Error::EDAMNotFoundException => ednfe
    # Parent Notebook GUID doesn't correspond to an actual notebook
    puts "EDAMNotFoundException: Invalid parent notebook GUID"
  end

  # Return created note object
  note
end

# download invoice file
file = download_invoice_viewsnet

# read invoice file
upload_file = File.open(File.path(file), "rb") do |io|
  io.read
end

# Create data object
data = Evernote::EDAM::Type::Data.new
data.size = upload_file.size
data.body = upload_file

# Create resource object
resource = Evernote::EDAM::Type::Resource.new
resource.mime = "application/pdf"
resource.data = data
resource.attributes = Evernote::EDAM::Type::ResourceAttributes.new
resource.attributes.fileName = File.basename(file)

# Note title time
year = Time.now.strftime("%Y")
month = Time.now.strftime("%m")

# put note with attachement file
put_note "#{year}年#{month}月ご利用代金明細照会｜ビュー・スイカカード", "", PARENT_NOTEBOOK_GUID, Array.new.push(resource), Array.new.push("VIEW's NET")
