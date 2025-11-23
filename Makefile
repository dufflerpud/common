#@HDR@	$Id$
#@HDR@		Copyright 2024 by
#@HDR@		Christopher Caldwell/Brightsands
#@HDR@		P.O. Box 401, Bailey Island, ME 04003
#@HDR@		All Rights Reserved
#@HDR@
#@HDR@	This software comprises unpublished confidential information
#@HDR@	of Brightsands and may not be used, copied or made available
#@HDR@	to anyone, except in accordance with the license under which
#@HDR@	it is furnished.
PROJECTSDIR?=$(shell echo $(CURDIR) | sed -e 's+/projects/.*+/projects+')
include $(PROJECTSDIR)/common/Makefile.std

ACCOUNTSDB=$(PROJECTDIR)/db/accounts.db
CPI_USER=$(PROJECTSDIR)/cpi/tests/cpi_user.pl

install:
		install -d -m 0777 $(dir $(ACCOUNTSDB))
		[ -f $(ACCOUNTSDB) ] || \
		    $(CPI_USER) \
			-database $(ACCOUNTSDB) \
			-init -administrator administrator -password 'CHANGEME!'
		chmod 666 $(ACCOUNTSDB)

%:
		@echo "Invoking std_$@ rule:"
		@$(MAKE) std_$@ ORIGINAL_TARGET=$@
