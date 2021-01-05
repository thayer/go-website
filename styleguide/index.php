<?php
 if ($handle = opendir('.')) {
   while (false !== ($file = readdir($handle)))
      {
          if ($file != "." && $file != ".." && $file != "index.php" && $file != "see.php")
	  {
          	$thelist .= '<h3><a href="'.$file.'">'.$file.'</a></h3>';
          }
       }
  closedir($handle);
  }
?>
<!DOCTYPE html>
<html>
<head>
  <title>Dartmouth Engineering Styleguide</title>
  <link
      rel="stylesheet"
      href="https://unpkg.com/tachyons@4.10.0/css/tachyons.min.css"
    />
</head>
<body class="sans-serif">
<div style="text-align: center;">
  <h1>Dartmouth Engineering Styleguide</h1>
  <h2><?=$thelist?></h2>
</div>
</body>
</html>
