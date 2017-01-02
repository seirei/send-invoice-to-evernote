# Load libraries required by the mechanize for browser emulator
require 'mechanize'
require 'uri'

# Define OMC URL for download invoices
OMC_LOGIN_URL = "https://ca.cedyna.co.jp/member/omcplus_login.html"
OMC_DOWNLOAD_URL = "https://ca.cedyna.co.jp/member/xt_pdf_download.aspx"
OMC_USER = "your user id" # login id for omc
OMC_PASS = "user password" # login password for omc
