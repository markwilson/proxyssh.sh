# SSH through proxy

Connect via SSH to a remote server via a proxy SSH server.

Usage:

Create a <profile>.conf in proxyssh.d/ following this format:-

	PROXYHOST="<proxy addr>"
	PROXYUSER="<proxy username>" # optional
	REMOTEHOST="<remote addr>"
	REMOTEUSER="<remote username>" # optional

Execute:-

	proxyssh.sh <profile>
