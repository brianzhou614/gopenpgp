package models

//EncryptedSplit when encrypt attachemt
type EncryptedSplit struct {
	DataPacket []byte
	KeyPacket  []byte
	Algo       string
}

//SessionSplit split session
type SessionSplit struct {
	Session []byte
	Algo    string
}

//EncryptedSigned encrypt_sign_package
type EncryptedSigned struct {
	Encrypted string
	Signature string
}

//DecryptSignedVerify decrypt_sign_verify
type DecryptSignedVerify struct {
	//clear text
	Plaintext string
	//bitmask verify status : 0
	Verify int
	//error message if verify failed
	Message string
}
