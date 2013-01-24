///<reference path="../def/angular.d.ts"/>
///<reference path="../def/underscore.d.ts"/>
///<reference path="../types.ts"/>

interface IHTMLFile {
  lastModifiedDate: Date;
  name: string;
  type: string; // mime type
  size: number; // bytes
}

interface BookParams extends ng.IRouteParamsService {
  bookId: string;
}

angular.module('controllers')
.controller('BookCtrl', function($scope, $routeParams: BookParams, $location:ng.ILocationService, $http:ng.IHttpService) {
  $scope.bookId = $routeParams.bookId

  $scope.book = null
  $scope.files = []

  loadBook()
  loadFiles()

  function loadBook() {
    $http.get("/books/" + $scope.bookId).success(function(book) {
      $scope.book = book
    })
  }

  function loadFiles() {
    $http.get("/books/" + $scope.bookId + "/files").success(function(files) {
      $scope.files = files
    })
  }

  $scope.save = function(book) {
    $http.put("/books/" + $scope.bookId, $scope.book).
      success(function() {
        $location.path("/admin")
      })
  }

  $scope.remove = function() {
    $http.delete('/books/' + $scope.book.bookId).success(function() {
      $location.path("/admin")
    })
  }

  $scope.removeFile = function(file:IFile) {
    $scope.files = _.without($scope.files, file)
    $http.delete('/files/' + file.fileId).success(function() {
      //loadFiles()
    })
  }

  $scope.isEditing = function(file) {
    return $scope.editing && $scope.editing.fileId == file.fileId
  }

  $scope.editFile = function(file:IFile) {
    $scope.editing = _.clone(file)
  }

  $scope.cancelEdit = function() {
    delete $scope.editing
  }

  $scope.updateFile = function(file) {
    file.name = $scope.editing.name
    $scope.cancelEdit()
    $http.put('/files/' + file.fileId, file).success(function() {
      //loadFiles()
    })
  }

  $scope.onDrop = function(files:IHTMLFile[]) {
    files.forEach(addFile)
  }

  $scope.isLoading = function(file:IFile) {
    return (file.fileId === undefined || file.fileId === null)
  }

  function toPendingFile(htmlFile:IHTMLFile):IFile {
    var ext = htmlFile.name.match(/\.(\w+)$/)[1]
    var name = htmlFile.name.replace("." + ext, "")

    // you can tell it's pending because it doesn't have url, fileId, bookId
    return {
      name:name,
      ext:ext,
      url:undefined,
      fileId:undefined,
      bookId:undefined,
    }
  }

  function addFile(file:IHTMLFile) {
    var pendingFile = toPendingFile(file)
    $scope.files.push(pendingFile)

    var formData = new FormData()
    formData.append('file', file)

    $http({
      method: 'POST',
      url: '/books/' + $scope.book.bookId + "/files",
      data: formData,
      // no idea why you need both of these, but you do
      transformRequest: angular.identity,
      headers: {'Content-Type': undefined},
    })
    .success(function(file:IFile) {
      console.log("ADDED FILE", file)
       _.extend(pendingFile, file)
    })
  }
})

