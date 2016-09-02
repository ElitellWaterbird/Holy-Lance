<?php
define("BUILD_FILE_NAME", "tz.php");
define("ENTER_FILE_NAME", "index.php");
$file_buffer = [];
$ignore_dir = [".git", "build"];
$ignore_file = ["./Makefile"];
$build_extension = ["php", "css", "js"];
$old_file_name_list = [];
$new_file_name_list = [];

function add_file_to_buffer($file_name)
{
	global $file_buffer, $build_extension, $old_file_name_list, $new_file_name_list;
	$old_file_name = $old_file_name_list[$file_name];
	$new_file_name = $new_file_name_list[$file_name];
	$file_info = pathinfo($file_name);
	$file_extension = empty($file_info['extension']) ? '' : $file_info['extension'];
	if (in_array($file_extension, $build_extension)){
		$file_buffer[$old_file_name]['extension'] = $file_extension;
		$file_buffer[$old_file_name]['content'] = file_get_contents($file_name);
			foreach ($old_file_name_list as $file_name_key => $old_file_name_value) {
				$file_buffer[$old_file_name]['content'] = str_replace($old_file_name_value, $new_file_name_list[$file_name_key], $file_buffer[$old_file_name]['content']);
			}
	}
}

function listDir($dir)
{
	global $ignore_dir, $ignore_file, $old_file_name_list, $new_file_name_list;
	if (is_dir($dir)) {
		if ($dh = opendir($dir)) {
			while (($file = readdir($dh)) !== false) {
				if ((is_dir($dir . "/" . $file)) && $file != "." && $file != "..") {
					if (!in_array($file, $ignore_dir)) {
						// echo $file . "\n";
						listDir($dir . $file . "/");
					}
				} else {
					if ($file != "." && $file != "..") {
						$file_name = $dir . $file;
						if (!in_array($file_name, $ignore_file)) {
							$old_file_name_list[$file_name] = str_replace("./", "", $file_name);
							$new_file_name_list[$file_name] = BUILD_FILE_NAME . "?file=" . urlencode($old_file_name_list[$file_name]);
							echo $file_name . "\n";
						}
					}
				}
			}
			closedir($dh);
		}
	}
}

if (!is_dir("./build")) {
	mkdir("./build");
}

listDir("./");

foreach ($old_file_name_list as $file_name => $old_file_name) {
	add_file_to_buffer($file_name);
}

$fp = fopen("./build/" . BUILD_FILE_NAME, 'w');
$entry_file = !empty($file_buffer[ENTER_FILE_NAME]) ? $file_buffer[ENTER_FILE_NAME] : '';
if (!$entry_file) {
	echo 'Entry file not found! ';
	exit(1);
}
unset($file_buffer[ENTER_FILE_NAME]);
foreach ($file_buffer as $file_name => $file) {
	fwrite($fp, '<?php
if (!empty($_GET["file"]) && $_GET["file"] == "' . $file_name . '"):
');
	if ($file['extension'] == 'css') {
		fwrite($fp, 'header("Content-type: text/css");');
	}
	fwrite($fp, '?>');
	fwrite($fp, $file['content']);
	fwrite($fp, '<?php
exit();
endif;
?>');
}
fwrite($fp, $entry_file['content']);
fclose($fp);