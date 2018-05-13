#include <unistd.h>
#include <errno.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <pwd.h>
#include <sys/types.h>

//This code will pass parameters to /prj/local/scripts/dosync perl script, that is to SUID to root perform data removal from Mesos agents
//
//By: Rami Krankurs, for GM ATCI, November 2017

int
main( int argc, char *argv[], char *envp[], int returnVal )
{
	int uid = getuid();
	if( setgid(getegid()) ) perror( "setgid" );
	if( setuid(geteuid()) ) perror( "setuid" );
	envp = 0; /* blocks IFS attack on non-bash shells */
	if(argc != 2 ){
		printf("Usage: mremove <directory name>\n");
		exit(1);
	}

	char  cmd[1024], format[] = "/prj/local/scripts/mremove %s %d\n";	//pass the directory name to the script.
	char mpath[] = "argv[1]";
	char * match2;
	match2 = strchr(argv[1], '\\/');
	if ((match2) != NULL)
	{
		printf("Usage: /prj/local/scripts/mremove <directory>\n");
		exit (1);
	}
	else {
		sprintf(cmd, format, argv[1], uid);
		system(cmd);
		return 0;
	}
}
