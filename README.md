# Send pdf file to Evernote #

This library, to download the invoice file from OMC Plus members site and VIEW's NET.
And send to Evernote the invoice file.

 * http://www.cedyna.co.jp/
 * https://viewsnet.jp/
 * http://evernote.com/

# Installing #

Download this repository, if you are using Mac, you don't need to install Git because Git is already installed. Bundler(bundle) is expect that it is installed. Start the Terminal, type the following commands:

    git clone https://github.com/seirei/send-invoice-to-evernote.git
    cd send-invoice-to-evernote
    bundle install --path vendor/bundle

# Usage #

You'll need an Evernote developer token to use this library. It is also possible to use the Sandbox token, If the first time.
If you know and available developer token, edit evernote_config.rb like

    # Define evernote for create note
    DEVELOPER_TOKEN = "your developer token"
    SANDBOX = true

to

    # Define evernote for create note
    DEVELOPER_TOKEN = "S=s1:U=279bf:E=13f92f..."
    SANDBOX = true

If you are running in a production environment, you should rewrite the SANDBOX flag to false.
