
$(function() {
    moment.lang('pt-br');
    $('span[data-moment]').each(function(idx, item) {
        var $item = $(item);
        var date = $item.attr('data-moment');
        $item.html(moment(date, 'DD/MM/YYYY HH:mm').fromNow());
    });

   function disqus() {
       var dsq = document.createElement('script'); dsq.type = 'text/javascript'; dsq.async = true;
       dsq.src = '//comsolid.disqus.com/embed.js';
       (document.getElementsByTagName('head')[0] || document.getElementsByTagName('body')[0]).appendChild(dsq);
   }

   $('#btn-load-disqus').click(function () {
       $(this).remove();
       disqus();
       return false;
   });
});
