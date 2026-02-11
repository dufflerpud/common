#indx#	Makefile - Build common files
#@HDR@	$Id$
#@HDR@
#@HDR@	Copyright (c) 2024-2026 Christopher Caldwell (Christopher.M.Caldwell0@gmail.com)
#@HDR@
#@HDR@	Permission is hereby granted, free of charge, to any person
#@HDR@	obtaining a copy of this software and associated documentation
#@HDR@	files (the "Software"), to deal in the Software without
#@HDR@	restriction, including without limitation the rights to use,
#@HDR@	copy, modify, merge, publish, distribute, sublicense, and/or
#@HDR@	sell copies of the Software, and to permit persons to whom
#@HDR@	the Software is furnished to do so, subject to the following
#@HDR@	conditions:
#@HDR@	
#@HDR@	The above copyright notice and this permission notice shall be
#@HDR@	included in all copies or substantial portions of the Software.
#@HDR@	
#@HDR@	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY
#@HDR@	KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
#@HDR@	WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE
#@HDR@	AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
#@HDR@	HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
#@HDR@	WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
#@HDR@	FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
#@HDR@	OTHER DEALINGS IN THE SOFTWARE.
#
#hist#	2026-02-10 - Christopher.M.Caldwell0@gmail.com - Created
########################################################################
#doc#	Makefile - Build common files
########################################################################
PROJECTSDIR?=$(shell echo $(CURDIR) | sed -e 's+/projects/.*+/projects+')
include $(PROJECTSDIR)/common/Makefile.std
XLTODO=$(subst .db,.todo,$(XLDB))

install:
		$(INSTALL) -d -m 0777 -o root -g root ${PROJECTDIR}/SIDS
		$(INSTALL) -m 0666 -o ${WUSER} -g ${WGROUP} /dev/null /var/log/common.log
		$(INSTALL) -d -m 0777 -o root -g root /var/log/stderr
		$(INSTALL) -d -m 0777 $(dir $(ACCOUNTSDB))
		[ -f $(XLDB) ] || $(CPI_DB) -new $(XLDB)
		[ -f $(ACCOUNTSDB) ] || \
		    $(CPI_USER) \
			-database $(ACCOUNTSDB) \
			-init -administrator $(ADMINISTRATOR) -password '$(BAD_PASSWORD)'
		[ -f $(XLTODO) ] || touch $(XLTODO)
		$(CHMOD) 0666 $(ACCOUNTSDB) $(XLDB) $(XLTODO)

%:
		@echo "Invoking std_$@ rule:"
		@$(MAKE) std_$@ ORIGINAL_TARGET=$@
