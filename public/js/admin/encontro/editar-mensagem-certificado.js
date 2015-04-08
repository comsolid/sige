
$(function () {
    var pdfData = atob($('#pdf-data').val());

    // Disable workers to avoid yet another cross-origin issue (workers need
    // the URL of the script to be loaded, and dynamically loading a cross-origin
    // script does not work).
    //
    // PDFJS.disableWorker = true;
    // In cases when the pdf.worker.js is located at the different folder than the
    // pdf.js's one, or the pdf.js is executed via eval(), the workerSrc property
    // shall be specified.
    //
    // PDFJS.workerSrc = '../../build/pdf.worker.js';
    // Opening PDF by passing its binary data as a string. It is still preferable
    // to use Uint8Array, but string or array-like structure will work too.
    PDFJS.getDocument({
        data: pdfData
    }).then(function (pdf) {
        // Fetch the first page.
        pdf.getPage(1).then(function (page) {
            var scale = 1.5;
            var viewport = page.getViewport(scale);
            // Prepare canvas using PDF page dimensions.
            var canvas = document.getElementById('the-canvas');
            var context = canvas.getContext('2d');
            canvas.height = viewport.height;
            canvas.width = viewport.width;
            // Render PDF page into canvas context.
            var renderContext = {
                canvasContext: context,
                viewport: viewport
            };
            page.render(renderContext);
        });
    });
});
