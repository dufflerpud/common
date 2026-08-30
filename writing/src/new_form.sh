#! /bin/sh

sed							\
	-e 's+{[A-Za-z0-9_][A-Za-z0-9_]*,+&QQQ+g'	\
	-e 's+,QQQ+\~+g'				\
	-e 's+[{}]++g'					\
