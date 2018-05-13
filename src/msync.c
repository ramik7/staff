#include <unistd.h>
#include <errno.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <pwd.h>
#include <sys/types.h>

//This code will pass parameters to /prj/local/scripts/dosync perl script, that is to SUID to root perform data replications to Apache Mesos agents
//local drives (FFD - Full Flash Drive, HDD - SATA Hard Drive)
//
//By: Rami Krankurs, for GM ATCI, November 2017

int
main( int argc, char *argv[], char *envp[], int returnVal )
{
	int uid = getuid();
	char ruid[30] = "--ruid";
	if( setgid(getegid()) ) perror( "setgid" );
	if( setuid(geteuid()) ) perror( "setuid" );
	envp = 0; /* blocks IFS attack on non-bash shells */
	if(argc != 5 ){
		printf("Usage: dosync --src <path_to_folder> --drive <hdd/ffd>\n");
		exit(1);
	}

	char  cmd[1024], format[] = "/prj/local/scripts/dosync %s %s %s %s %s %d \n";
	sprintf(cmd, format, argv[1], argv[2], argv[3], argv[4], ruid, uid);
	system(cmd);
	return 0;
}
