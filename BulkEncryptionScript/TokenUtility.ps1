#
# TokenUtility.ps1
#

# Used to manually encrypt Web App Key / Auth Token, along with a new decryption key file.

$scriptLocation = "C:\set-script-location-here\token files\"

# To generate a new Key, uncomment the block below...
$KeyFile = "C:\Users\damoo\source\repos\BulkEncryption\BulkEncryption\BulkEncryptionScript\token files\keyfile.txt"
$Key = New-Object Byte[] 32   # You can use 16, 24, or 32 for AES
[Security.Cryptography.RNGCryptoServiceProvider]::Create().GetBytes($Key)
$Key | out-file $KeyFile

# Read the string, encrypt and pipe to file
$Key = Get-Content $KeyFile
$openTokenFile = $scriptLocation + "token files\original-token.txt"
$secureTokenFile = $scriptLocation + "token files\encrypted-token.txt"
$secureToken = Get-Content $openTokenFile | ConvertTo-SecureString -AsPlainText -Force
$secureToken | ConvertFrom-SecureString -key $Key | Out-File $secureTokenFile

# App Key - repeat the above
$openKeyFile = $scriptLocation + "token files\original-appkey.txt"
$secureKeyFile = $scriptLocation + "token files\encrypted-appkey.txt"
$secureKey = Get-Content $openKeyFile | ConvertTo-SecureString -AsPlainText -Force
$secureKey | ConvertFrom-SecureString -key $Key | Out-File $secureKeyFile


# Examples of how to read back to open string
#$readToken = Get-Content $PasswordFile
#$readToken2 = ConvertTo-SecureString $readToken -Key $Key
#$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($readToken2)
#$UnsecurePassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
#$UnsecurePassword | out-file "C:\temp\raw.txt"
