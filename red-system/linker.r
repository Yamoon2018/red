REBOL [
	Title:   "Red/System linker"
	Author:  "Nenad Rakocevic"
	File: 	 %linker.r
	Rights:  "Copyright (C) 2011 Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/master/BSD-3-License.txt"
]

linker: context [
	verbose: 0					;-- logs verbosity level
	version: 1.0.0
	cpu-class: 'IA32			;-- default target
	
	job-class: context [
		format: 				;-- 'PE | 'ELF | 'Mach-o
		type: 					;-- 'exe | 'obj | 'lib | 'dll
		target:					;-- CPU identifier
		sections:				;-- code/data sections
		flags:					;-- global flags
		sub-system:				;-- target environment (GUI | console)
		symbols:				;-- symbols table
		output:					;-- output file name (without extension)
		buffer: none
	]
	
	PE:		 do %formats/PE.r
	ELF:	 do %formats/ELF.r
	;Mach-o: do %formats/mach-o.r			; TBD
	
	resolve-symbol-refs: func [job buf code-ptr data-ptr pointer][
		foreach [name spec] job/symbols [
			unless empty? spec/3 [
				switch spec/1 [
					global [
						pointer/value: data-ptr + spec/2
						foreach ref spec/3 [change at buf ref third pointer]
					]
					native-ref [
						pointer/value: code-ptr + spec/2
						foreach ref spec/3 [change at buf ref third pointer]
					]
				]
			]
		]
	]

	make-filename: func [job /local obj][
		obj: get in self job/format
		join job/output select obj/defs/extensions job/type
	]
	
	build: func [job [object!] /in path /local file][
		unless job/target [job/target: cpu-class]
		job/buffer: make binary! 100 * 1024
		
		switch job/format [
			PE     [PE/build 	 job]
			ELF    [ELF/build 	 job]
			Mach-o [Mach-o/build job]
		]
		file: make-filename job
		if in [file: path/:file]

		if verbose >= 1 [print ["output file:" file]]	
		write/binary file job/buffer
	]

]