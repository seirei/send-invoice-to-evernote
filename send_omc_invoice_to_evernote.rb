# Load our dependencies and configuration settings
$LOAD_PATH.push(File.expand_path(File.dirname(__FILE__)))
require 'evernote_config.rb'
require 'omc_config.rb'

#
# download invoice pdf file
#
def download_invoice_omc(year=nil, month=nil)
  # Get the agent instance
  agent = Mechanize.new

  # Logged for omc card web page, get tmp_id and tmp_str for using download
  tmp_id = tmp_str = ""
  agent.get(OMC_LOGIN_URL) do |page|
    login_result = page.form_with(name: 'form1') do |login|
      login.field_with(name: 'sid').value = OMC_USER # login id for omc
      login.field_with(name: 'pw').value = OMC_PASS # login password for omc
    end.submit
    uri = URI(login_result.uri)
    query = Hash[URI.decode_www_form(uri.query)]
    tmp_id = query['TmpId']
    tmp_str = query['TmpStr']
  end

  # year and month for download invoice
  year = Time.now.strftime("%Y") if year.nil?
  month = Time.now.strftime("%m") if month.nil?

  # Get the pdf filename
  file_name = "#{year}#{month}.pdf"

  # File open for write and binary mode
  pdf_file = File.open(file_name,'wb')

  # Start download and create invoice pdf
  pdf_file.puts agent.get_file("#{OMC_DOWNLOAD_URL}?TmpID=#{tmp_id}&TmpStr=#{tmp_str}&strintMonth=#{month}&strbkwork_str=#{year}&strdecision=1&S_work=#{year}#{month}&str_year=#{year}#{month}&Old_chk=")

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
file = download_invoice_omc

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
put_note "#{year}年#{month}月ご利用代金明細照会｜セディナカード", "", PARENT_NOTEBOOK_GUID, Array.new.push(resource), Array.new.push("OMC")
