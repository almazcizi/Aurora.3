//checks if a file exists and contains text
//returns text as a string if these conditions are met
/proc/return_file_text(filename)
	if(fexists(filename) == 0)
		log_error("File not found ([filename])")
		return

	var/text = file2text(filename)
	if(!text)
		log_error("File empty ([filename])")
		return

	return text

/proc/get_subfolders(var/root)
	var/list/folders = list()
	var/list/contents = flist(root)

	for(var/file in contents)
		//Check if the filename ends with / to see if its a folder
		if(copytext(file,-1,0) != "/")
			continue
		folders.Add("[root][file]")

	return folders

//Sends resource files to client cache
/client/proc/getFiles()
	for(var/file in args)
		send_rsc(src, file, null)

/client/proc/browse_files(root="data/logs/", max_iterations=10, list/valid_extensions=list(".txt",".log",".htm", ".json"))
	var/path = root

	for(var/i=0, i<max_iterations, i++)
		var/list/choices = sortList(flist(path))
		if(path != root)
			choices.Insert(1,"/")

		var/choice = input(src,"Choose a file to access:","Download",null) as null|anything in choices
		switch(choice)
			if(null)
				return
			if("/")
				path = root
				continue
		path += choice

		if(copytext(path,-1,0) != "/")		//didn't choose a directory, no need to iterate again
			break

	var/valid_extension = FALSE
	for(var/e in valid_extensions)
		if(findtext(path, e, -(length(e))))
			valid_extension = TRUE

	if( !fexists(path) || !valid_extension )
		to_chat(src, "<span class='warning'>Error: browse_files(): File not found/Invalid file([path]).</span>")
		return

	return path

#define FTPDELAY 200	//200 tick delay to discourage spam
/*	This proc is a failsafe to prevent spamming of file requests.
	It is just a timer that only permits a download every [FTPDELAY] ticks.
	This can be changed by modifying FTPDELAY's value above.

	PLEASE USE RESPONSIBLY, Some log files canr each sizes of 4MB!	*/
/client/proc/file_spam_check()
	var/time_to_wait = fileaccess_timer - world.time
	if(time_to_wait > 0)
		to_chat(src, "<span class='warning'>Error: file_spam_check(): Spam. Please wait [round(time_to_wait/10)] seconds.</span>")
		return 1
	fileaccess_timer = world.time + FTPDELAY
	return 0
#undef FTPDELAY
