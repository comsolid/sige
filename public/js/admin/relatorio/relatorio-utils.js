
function dateFormat(date) {
   return sprintf("%02d/%02d/%04d",
      (date.getUTCDate() + 1),
      (date.getMonth() + 1),
      date.getFullYear()
   );
}
