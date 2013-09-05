///<reference path='../types.ts'/>
///<reference path='../def/knox.d.ts'/>
///<reference path='../def/q.d.ts'/>

import knox = require('knox')
import q = require('q')

var BUCKET = "librosapp"
var BUCKET_URL = "http://" + BUCKET + ".s3.amazonaws.com"
var s3client = knox.createClient({
  key:"AKIAIMGQVHF2DZ7UN32Q",                         // DELETE ME (belongs to scott)
  secret:"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",
  bucket:BUCKET,
})

export var bucketUrl = BUCKET_URL

export function fileUpload(file:IFile, source:IUploadFile) {
  return upload(fileToUrlPath(file), source)
}

export function fileRemove(file:IFile):q.IPromise<void> {
  return remove(fileToUrlPath(file))
}

export function upload(remotePath:string, source:IUploadFile) {
  var deferred = q.defer()
  s3client.putFile(source.path, remotePath, {'Content-Type':source.mime}, <knox.IResponseCallback> deferred.makeNodeResolver())
  return deferred.promise
}

export function remove(remotePath:string) {
  var deferred = q.defer()
  s3client.deleteFile(remotePath, <knox.IResponseCallback> deferred.makeNodeResolver())
  return deferred.promise
}

export function fullUrl(remotePath:string) {
  return BUCKET_URL + remotePath
}

export function fileToUrl(file:IFile):string {
  // return "bob"
  return fullUrl(fileToUrlPath(file))
}

// need more info that that! need the extention, etc
function fileToUrlPath(file:IFile):string {
  // fileId has the extension in it now
  return "/" + file.fileId
}

export function ext(source:IUploadFile):string {
  return source.name.match(/\.(\w+)$/)[1]
}


