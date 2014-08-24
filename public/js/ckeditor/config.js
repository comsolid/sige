/**
 * @license Copyright (c) 2003-2012, CKSource - Frederico Knabben. All rights reserved.
 * For licensing, see LICENSE.html or http://ckeditor.com/license
 */

CKEDITOR.editorConfig = function (config) {
   // Define changes to default configuration here. For example:
   //config.language = 'pt_BR';
   // config.uiColor = '#AADC6E';
   //config.width = "750px";
   config.format_pre = {
      element : 'pre',
      attributes : {
         'class' : 'prettyprint'
      }
   };
   
   config.toolbar = 'MyToolbar';
 
   config.toolbar_MyToolbar =
   [
       {
          name: 'document', 
          items : [ 'Source' ]
       },
       {
          name: 'clipboard', 
          items : [ 'Cut', 'Copy', 'Paste', 'PasteText', 'PasteFromWord', '-', 'Undo', 'Redo' ]
       },
       {
          name: 'editing', 
          items : [ 'Find', 'Replace', '-', 'SelectAll', '-', 'SpellChecker', 'Scayt' ]
       },
       {
          name: 'basicstyles', 
          items : [ 'Bold', 'Italic', 'Underline', 'Strike', 'Subscript', 'Superscript', '-', 'RemoveFormat' ]
       },
       '/',
       {
          name: 'paragraph', 
          items : [ 'NumberedList', 'BulletedList', '-', 'Outdent', 'Indent', '-', 'Blockquote',
          '-', 'JustifyLeft', 'JustifyCenter', 'JustifyRight', 'JustifyBlock', '-', 'BidiLtr', 'BidiRtl' ]
       },
       {
          name: 'links', 
          items : [ 'Link', 'Unlink' ]
       },
       {
          name: 'insert', 
          items : [ 'Image' ]
       },
       {
          name: 'tools', 
          items : [ 'Maximize', 'About' ]
       }
   ];
};
