(* ::Package:: *)

(* ::Chapter:: *)
(*DocFind*)


BeginPackage["DocFind`"]


DocFind::usage="Finds all the docs for a given pattern";
SymbolNameMatchQ::usage=
	"StringMatchQ on just the SymbolName (also works for strings)";
SymbolDetermineType::usage=
	"Determines symbol type";
OpsFind::usage=
	"Finds all the options for a given object and pattern";
MsgFind::usage="Finds all the messages for a given object and MessageName pattern";


(* ::Subsection:: *)
(*Package Scope*)


BeginPackage["`Package`"];
GetUsage::usage=
	"Finds the uses of a symbol";
FormattedUsage::usage=
	"Formats a GetUsage call";
FormattedDefs::usage=
	"FormattedUsage with Full";
DocFile::usage="Returns the doc file for a given symbol";
OpenDocs::usage="Opens a documentation notebook for the symbol name";
ContextOrdering::usage="The ordering function for context notebooks";
ContextNotebook::usage="Formats a notebook to give docs for an entire context";
DocsDialog::usage=
	"Creates a documentation search dialog";
$DockDocDialog::usage=
	"A symbol formatted to the docs dialog in the documentation search palette";
PaneColumn::usage="Formats a column in a pane and frame";
EndPackage[]


(* ::Section:: *)
(*Implementation*)


Begin["`Private`"];


(* ::Subsubsection::Closed:: *)
(*PaneColumn*)


Options[PaneColumn]=Join[{
Dividers->True,
ItemSize->Automatic,
ImageSize->{Automatic,{Automatic,250}},
Scrollbars->{False,Automatic},
AppearanceElements->None,
Framed->False,
FrameMargins->0,
FrameStyle->Black,
ImageSizeAction->"Scrollable"},
FilterRules[Options[Column],
Except[Dividers|ItemSize]],
FilterRules[Options[Pane],
Except@(
Alternatives@@Join[
Options[Column],
{ImageMargins,ImageSize,Scrollbars,AppearanceElements}
])
],
FilterRules[Options[Framed],Except@(
Alternatives@@Join[
Options[Column],
Options[Pane],
{FrameMargins,FrameStyle}]
)]
];
PaneColumn[things_,ops:OptionsPattern[]]:=Pane[
Column[things,
Dividers->With[{style=Replace[OptionValue@FrameStyle,
l_List:>Last@Cases[l,Except[_List],\[Infinity]]]
},
Switch[OptionValue@Dividers,
True,{
{},Thread[Range[2,Length@things]->style]},
False,{},
_,style
]
],
FilterRules[Join[{ItemSize->If[OptionValue@ItemSize===Automatic,Replace[OptionValue@ImageSize,{
_Integer|_Scaled|Full|{_Integer|_Scaled|Full,_}:>{1000,Automatic},
_:>Automatic
}]
],ops},Options@PaneColumn],Options@Column]
],
FilterRules[Join[{FrameMargins->{{0,-1},{1,1}},ops},Options@PaneColumn],Options@Pane]
]//If[TrueQ@OptionValue@Framed,
Framed[#,FilterRules[Join[{ops},Options@PaneColumn],Options@Framed]]&,
Identity]


(* ::Subsubsection::Closed:: *)
(*HyperlinkBrowse*)


Options[HyperlinkBrowse]=Join[
	{
		Function->None,
		Format->Automatic
		},
	Options@PaneColumn
	];
HyperlinkBrowse[
	links:{__},
	buttonFunction:Except[_Rule|_RuleDelayed]:None,
	formatFunction:Except[_Rule|_RuleDelayed]:Automatic,
	ops:OptionsPattern[]]:=
		With[{
			format=
				Replace[formatFunction,
					Automatic:>
						Replace[OptionValue@Format,
							Automatic:>Replace[{s_String:>FileNameTake@s}]
							]
						],
			function=
				Replace[buttonFunction,
					Automatic:>OptionValue@Function
					]
			},
			PaneColumn[
				With[{f=format@#},
					If[buttonFunction=!=None,
						StatusArea[
							Button[
								Mouseover[
									Style[f,"Hyperlink"],
									Style[f,"HyperlinkActive"]
									],
							buttonFunction@#,
							Appearance->"Frameless",
							BaseStyle->{"Hyperlink"}
							],
							#],
						StatusArea[Hyperlink[f,#],#]		
						]
					]&/@links,
				FilterRules[{ops},
					Options@PaneColumn
					]
				]
			]


(* ::Subsubsection::Closed:: *)
(*DocFile*)


DocFile[symbolName_String,mode_:Automatic]:=TemplateApply[
Switch[mode,
"Web"|Hyperlink|URL,
URLBuild@<|"Scheme"->"https",
"Domain"->"reference.wolfram.com",
"Path"->{"language","ref","``.html"}
|>,
Automatic|File,
FileNameJoin@{$InstallationDirectory, "Documentation", "English","System", "ReferencePages","Symbols","``.nb"}
],
symbolName]


(* ::Subsubsection::Closed:: *)
(*PrintDefinitionsNotebook*)


PrintDefinitionsNotebook[nb_,symbolName_]:=
	Block[{GeneralUtilities`PackageScope`$EmbedSymbolBoxStyles=True,
		GeneralUtilities`Debugging`PackagePrivate`$PrintDefinitionsBackground=None,
		CreateDocument =(NotebookWrite[nb,
			#/.GeneralUtilities`PrintDefinitions->GeneralUtilities`PrintDefinitionsLocal,
			None,
			AutoScroll->False]&)
		},
	ToExpression[symbolName,StandardForm,GeneralUtilities`PrintDefinitions]
	];


(* ::Subsubsection::Closed:: *)
(*OpenDocs*)


OpenDocs[
	symbolName:_String,
	fileSource:_String|Automatic:Automatic,
	docNB:_NotebookObject|CreateNotebook|Automatic:Automatic,
	ops:OptionsPattern[Notebook]]:=
	Module[{
		file=Replace[fileSource,Automatic:>DocFile@symbolName],
		winTit="Documentation Notebook: "<>symbolName,
		nb=Replace[docNB,{
				Automatic|_NotebookObject?(NotebookInformation@#===$Failed&):>$DocPage,
				CreateNotebook:>
					Quiet[
						CreateNotebook[ops,
							WindowTitle->"Documentation Notebook: "<>symbolName,
							System`ClosingSaveDialog->False,
							CellMargins->{{100,Automatic},{100,Automatic}},
							StyleDefinitions->
								FrontEnd`FileName[{"Wolfram"},"Reference.nb",CharacterEncoding->"UTF-8"]
							],
						ClosingSaveDialog::shdw]
					}]},
		If[MatchQ[nb,
			Except[_NotebookObject]|_NotebookObject?(NotebookInformation@#===$Failed&)],
			nb=If[
				FreeQ[
					CurrentValue[EvaluationNotebook[],StyleDefinitions],
					_String?(StringContainsQ["Palette"|"Dialog"|"PrivateStylesheetFormatting"])
					],
				Documentation`HelpLookup[symbolName,EvaluationNotebook[]],
				Documentation`HelpLookup[symbolName,None]
				];
			If[docNB===Automatic,$DocPage=nb];,
			If[FileExistsQ@file//TrueQ,
				With[{nbops=
					FilterRules[
						Join[{ops},Replace[AbsoluteOptions@nb,$Failed->{}]],
						Except[WindowTitle]]},
					NotebookPut[Get@file,nb,Sequence@@Prepend[nbops,WindowTitle->winTit]]
					],
				Do[
					If[Not@(Deletable/.Options[c,Deletable]),SetOptions[c,Deletable->True]];,
					{c,Cells@nb}];
				NotebookDelete[Cells@nb];
				SetOptions[nb,WindowTitle->winTit]
				]
			];
	SetSelectedNotebook@nb;
	SelectionMove[nb,After,Notebook,AutoScroll->False];
	NotebookWrite[nb,
		Cell["Definitions Block","Section",CellFrame->{{0,0},{1,1}}],
		None,
		AutoScroll->False];
	Replace[
		Replace[
			ToExpression[symbolName,StandardForm,HoldComplete],
			HoldComplete[s_]:>MessageName[s,"usage"]
			],
		e:Except[_MessageName]:>
			NotebookWrite[nb,Cell[BoxData[e],"Output"],None,AutoScroll->False]
		];
	PrintDefinitionsNotebook[nb,symbolName];
	NotebookWrite[nb,
		Cell["","Section",
				CellFrame->{{0,0},{1,1}}],None,AutoScroll->False];
		SelectionMove[nb,Before,Notebook];
		nb
	];


OpenDocs[s_ToString,o___]:=OpenDocs[Evaluate@s,o]
OpenDocs[sym_Symbol,o___]:=OpenDocs[ToString@Unevaluated@sym,o];
OpenDocs~SetAttributes~HoldFirst;


(* ::Subsubsection::Closed:: *)
(*SymbolNameMatchQ*)


SymbolNameMatchQ[s_Symbol,pat_]:=
	StringMatchQ[SymbolName@Unevaluated[s],pat];
SymbolNameMatchQ[s_String,pat_]:=
	StringMatchQ[Last@StringSplit[s,"`"],pat];
SymbolNameMatchQ[e:Except[_Symbol],pat_]:=
	SymbolNameMatchQ[e,pat];
SymbolNameMatchQ[pat_][e_]:=
	SymbolNameMatchQ[e,pat];
SetAttributes[SymbolNameMatchQ,HoldFirst];


(* ::Subsubsection::Closed:: *)
(*SymbolDetermineType*)


docFindValues[s_,type_]:=
	Quiet[
		Replace[type[s],
			Except[_List]->{}]
		];
docFindValues~SetAttributes~HoldFirst;


$SymbolTypeNames=
	<|
		OwnValues->"Constant",
		DownValues->"Function",
		UpValues->"Object",
		SubValues->"Operator",
		FormatValues->"Wrapper"
		|>;
$SymbolNameTypes=
	AssociationThread[
		Values@$SymbolTypeNames,
		Keys@$SymbolTypeNames
		];
SymbolDetermineType//Clear;
SymbolDetermineType[s_Symbol,all:True|False:False]:=
	Catch[
		Replace[
			Map[
				If[SymbolDetermineType[s,$SymbolTypeNames[#]],
					If[all,
						$SymbolTypeNames[#],
						Throw[$SymbolTypeNames[#]]
						],
					Nothing
					]&,
				Keys@$SymbolTypeNames
				],
			{}->"Inert"
			]
		];
SymbolDetermineType[s_Symbol,$SymbolTypeNames[OwnValues]]:=
	(10.4<=$VersionNumber&&System`Private`HasOwnCodeQ@s)||
		Length@docFindValues[s,OwnValues]>0;
SymbolDetermineType[s_Symbol,$SymbolTypeNames[DownValues]]:=
	(10.4<=$VersionNumber&&System`Private`HasDownCodeQ@s)||
		Length@docFindValues[s,DownValues]>0;
SymbolDetermineType[s_Symbol,$SymbolTypeNames[SubValues]]:=
	(10.4<=$VersionNumber<=11.1&&System`Private`HasSubCodeQ@s)||
		Length@docFindValues[s,SubValues]>0;
SymbolDetermineType[s_Symbol,$SymbolTypeNames[UpValues]]:=
	(10.4<=$VersionNumber&&System`Private`HasUpCodeQ@s)||
		Length@docFindValues[s,UpValues]>0;
SymbolDetermineType[s_Symbol,$SymbolTypeNames[FormatValues]]:=
	(10.4<=$VersionNumber&&System`Private`HasPrintCodeQ@s)||
		Length@docFindValues[s,FormatValues]>0;
SymbolDetermineType[s_Symbol,"Inert"]:=
	SymbolDetermineType[s]==="Inert";
SymbolDetermineType[s_Symbol,
	Verbatim[Alternatives][t__?(KeyMemberQ[$SymbolNameTypes,#]&)]]:=
	Or@@Map[SymbolDetermineType[s,#]&,{t}];
SymbolDetermineType[s_Symbol,Or[t__?(KeyMemberQ[$SymbolNameTypes,#]&)]]:=
	Or@@Map[SymbolDetermineType[s,#]&,{t}];
SymbolDetermineType[s_Symbol,And[t__?(KeyMemberQ[$SymbolNameTypes,#]&)]]:=
	And@@Map[SymbolDetermineType[s,#]&,{t}];
SymbolDetermineType[s_String,e___]:=
	ToExpression[s,StandardForm,Function[Null,SymbolDetermineType[#,e],HoldFirst]];
SymbolDetermineType[s:{__String},e___]:=
	AssociationThread[
		s,
		ToExpression[s,StandardForm,Function[Null,SymbolDetermineType[#,e],HoldFirst]]
		];
SymbolDetermineType[{},___]:=
	<||>;
SymbolDetermineType~SetAttributes~HoldFirst;


(* ::Subsubsection::Closed:: *)
(*DocFind*)


Options@DocFind=
	Join[
		{
			Format->True,
			Context->None,
			Autocomplete->True,
			SortBy->None,
			Sort->None,
			Hyperlink->Automatic,
			ButtonFunction->Automatic,
			Select->Identity
			},
		Options[Names],
		Options@PaneColumn
		];


With[{
	callablePattern=(
	Except[
		None|_List|_String|_Rule|
		_Alternatives|_StringExpression|Automatic|
		_?(NumericQ)|_?(BooleanQ)|_?StringPattern`StringPatternQ|
		_?AtomQ
		]
		)
	},
DocFind[
	name:_?StringPattern`StringPatternQ:"*",
	cont:(_?StringPattern`StringPatternQ|Automatic):Automatic,
	sortBySorting:None|callablePattern:None,
	ops:OptionsPattern[]
	]:=
	Module[{searchName,names,selectBy},
		searchName=
			StringExpression@@{
				#context,
				If[#autocomp,"*",""],
				#name,
				If[#autocomp,"*",""]
				}&@<|
						"context"->
							Replace[Except[_?StringPattern`StringPatternQ]->""]@
								Replace[cont, 
									{
										s_String?(Not@*StringEndsQ["`"]):>s<>"`",
										Automatic:>Alternatives@@$Packages
										}
									],
						"name"->Replace[name,Verbatim[Verbatim][s_]:>s],
						"autocomp"->
							Replace[name,{_Verbatim->False,_:>TrueQ[OptionValue@Autocomplete]}]
						|>;
		names=Names[searchName,FilterRules[{ops},Options[Names]]];
		
		names=
			Replace[
				OptionValue[Select],{
				Identity:>
					names,
				match:
					_String?(
						Not@MatchQ[#,"Inert"]&&
						Not@KeyMemberQ[$SymbolNameTypes,#]
						&)|
					Verbatim[Alternatives][__?(Not@KeyMemberQ[$SymbolNameTypes,#]&)]|
					_StringExpression:>
					Select[names,StringMatchQ[match]],
				
				s:(_StringMatchQ|_StringContainsQ|_StringStartsQ|_StringEndsQ):>
					Select[names,s],
				s:(Not@*(_StringMatchQ|_StringContainsQ|_StringStartsQ|_StringEndsQ)):>
					Select[names,s],
				s_:>
					With[{f=
						Replace[s,{
							"Inert"|_?(KeyMemberQ[$SymbolNameTypes,#]&):>
								Function[Null,
									SymbolDetermineType[#,s],
									HoldFirst],
							((Alternatives|Or|And)[__?(KeyMemberQ[$SymbolNameTypes,#]&)]):>
								Function[Null,
									SymbolDetermineType[#,s],
									HoldFirst],
							Query[f1_,o___]:>
								Function[Null,
									Fold[#2@#&,
										f1[Unevaluated[#]],
										{o}],
									HoldFirst
									]
								}
							]
						},
						Pick[names,
							Replace[
								ToExpression[
									names,
									StandardForm,
									Hold],
								Hold[sym_]:>
									f[Unevaluated[sym]], 
								1
								]
							]
						]
				}];
		names=
			Replace[sortBySorting,{
				sort1:callablePattern:>
					SortBy[names,
						Replace[sort1[#],
							b:True|False:>
								Boole@(*Not@*)b
							]&
						],
				_:>Replace[OptionValue@SortBy,{
						f:callablePattern:>
							SortBy[names,
								Replace[f[#],
									b:True|False:>
										Boole@Not@b
									]&
								],
						_:>Replace[OptionValue@Sort,{
								g:callablePattern:>
									Sort[names,g],
								_:>
									SortBy[names,StringLength]
								}]
						}]
				}];
			If[OptionValue[Format]=!=False,
				If[Length@names>0,
					With[{buttonFunction=
						Replace[OptionValue@ButtonFunction,
							Automatic->(
								If[URLParse[#2]["Scheme"]===None,
									OpenDocs@#1,
									SystemOpen@#2
									]&)
								]},
						Switch[Format,
							Links,
								Table[
									With[{n=n,h=DocFile[n,OptionValue@Hyperlink]},
										Interpretation[
											Button[
												Mouseover[
													Style[n,"Hyperlink"],
													Style[n,"HyperlinkActive"]],
												buttonFunction[n,h],
												Appearance->"Frameless",
												Method->"Queued"
												],
											ToExpression@n
											]
										],
									{n,names}
									],
						_,
							Interpretation[
								PaneColumn[
									Table[
										With[{n=n,h=DocFile[n,OptionValue@Hyperlink]},
											Interpretation[
												Button[
													Mouseover[
														Style[n,"Hyperlink"],
														Style[n,"HyperlinkActive"]],
													buttonFunction[n,h],
													Appearance->"Frameless",
													Method->"Queued"
													],
												ToExpression@n
												]
											],
										{n,names}
										],
									FilterRules[{ops,Options@DocFind},Options@PaneColumn]
									],
								ToExpression[names, StandardForm, Defer]
								]
							]
						],
					None],
				names
				]
			]
		];


$DocFindInterestingContexts=
	{
			"System`",
			"System`Private`",
			"System`Convert`",
			"System`*`",
			"Internal`",
			"FrontEnd`",
			"FEPrivate`",
			"PacletManager`",
			"MathLink`",
			"GeneralUtilities`",
			"TypeSystem`",
			"Dataset`",
			"Documentation`"
			};


PackageAddAutocompletions[
	"DocFind",
	{
		None,
		$DocFindInterestingContexts
		}
	]


(* ::Subsubsection::Closed:: *)
(*OpsFind*)


Options@OpsFind:=
	Append[Options@DocFind,Function:>Options];
OpsFind[sym:Except@_List,stuff:(Except[_Rule|_RuleDelayed]...),ops:OptionsPattern[]]:=
	With[{opList=
		Replace[
			Replace[sym,{
				_CellObject:>Replace[
					OptionValue[Function],
					Options->AbsoluteOptions]@sym,
				_:>OptionValue[Function]@sym
				}],{
			o:Except[_List]:>{}
			}]
			},
		OpsFind[opList,stuff,ops]
	];
OpsFind[options_List,
		pattern:_String|_StringExpression|_Alternatives:"*",
		sortBySorting:_Function|_Symbol?(#=!=None&):None,
		ops:OptionsPattern[]]:=
	With[{buttonFunction=Replace[
		OptionValue@ButtonFunction,{
			NotebookWrite->(
				SelectionMove[EvaluationCell[],After,Cell];
				NotebookWrite[InputNotebook[],Cell[BoxData@ToBoxes@#,"Output"]]
				&),
			Automatic|Hyperlink->(If[
				MatchQ[First@#,_Symbol],
				Evaluate@ToString@First@#//OpenDocs,
				Print[First@#<>" is not a symbol"]
				]&)
			}]},
			With[{c=Cases[
				{#,ToString[First@#]}&/@options,
				{op_,name_?(
					StringMatchQ[#,
						If[
							MatchQ[pattern,_String],
							"*"<>pattern<>"*",
							___~~pattern~~___
							]]&)}:>{name,
									Button[
										Tooltip[
											Mouseover[
												Style[First@op,"Hyperlink"],
												Style[First@op,"HyperlinkActive"]
												],op],
										buttonFunction[op],
										Appearance->"Frameless",
										Method->"Queued"]
										}]
								},
					If[Length@c>0,
						With[{sortedC=
			Replace[
							Replace[sortBySorting,
				Except[_Function|_Symbol?(#=!=None&)]:>OptionValue@SortBy
				],{
										f:_Function|_Symbol?(#=!=None&):>
											With[{firsts=SortBy[First/@c,f]},
												SortBy[c,Position[firsts,First@#]&]
											],
										_:>Replace[OptionValue@Sort,{
												f:_Function|_Symbol?(#=!=None&):>
													With[{firsts=Sort[First/@c]},
														SortBy[c,Position[firsts,First@#]&]
														],
												_:>With[{firsts=SortBy[First/@c,StringLength]},
														SortBy[c,Position[firsts,First@#]&]
														]
													}]
											}]},
						PaneColumn[
							Last/@sortedC,
							FilterRules[{ops,Options@OpsFind},Options@PaneColumn]
							]
						],
			None]
					]
			]


(* ::Subsubsection::Closed:: *)
(*MsgFind*)


MsgFind//Clear


Options@MsgFind=
	Join[
		Options@PaneColumn,
		Options@StringContainsQ,
		Options@Names,
		{
			"SearchBody"->False
			}
		];
MsgFind[{syms___Symbol},mpat_?(StringPattern`StringPatternQ),ops:OptionsPattern[]]:=
	With[
		{
			sco=Sequence@@FilterRules[{ops}, Options@StringContainsQ],
			sb=TrueQ@OptionValue@"SearchBody"
			},
		If[Length@#>0,
					PaneColumn[#,
						FilterRules[
							{ops,Options@MsgFind},
							Options@PaneColumn
							]
						],
					None
					]&@
		Quiet@
		Flatten@
			List@
			ReleaseHold@
			Map[
				Function[
					sym,
					With[{m=First/@Messages@sym},
						Cases[m,
							If[sb,
								Verbatim[HoldPattern][
									mn_MessageName?(StringContainsQ[___~~mpat~~___, sco])
									],
								HoldPattern[
									Verbatim[HoldPattern][
										mn:MessageName[sym,
												mname_?(StringContainsQ[___~~mpat~~___, sco])
												]
											]
									]
								]:>
								Button[
									Tooltip[
										Mouseover[
											Style[HoldForm[mn],"Hyperlink"],
											Style[HoldForm[mn],"HyperlinkActive"]
											],
										mn
										],
									Print@
									Interpretation[
										MessageObject@
											<|
												"MessageSymbol":>sym,
												"MessageTag"->mname,
												"MessageTemplate"->mn
												|>,
										MessageObject@
											<|
												"MessageSymbol":>sym,
												"MessageTag"->mname,
												"MessageTemplate"->mn
												|>
										],
									Method->"Queued",
									Appearance->"Frameless"
									]
								]
						],
				HoldFirst
				],
			Hold[syms]
			]
		];
MsgFind[sym_Symbol,mpat_?(StringPattern`StringPatternQ),ops:OptionsPattern[]]:=
	MsgFind[{sym}, mpat, ops];
MsgFind[
	names:_?(StringPattern`StringPatternQ):"*",
	mpat_?(StringPattern`StringPatternQ),
	ops:OptionsPattern[]
	]:=
Replace[
	Thread[
		ToExpression[
			Names[names, FilterRules[{ops}, Options@Names]], 
			StandardForm, 
			Hold
			],
		Hold
		],
	Hold[s_]:>MsgFind[s, mpat, ops]
	];
MsgFind[
	e_,
	mpat_?(StringPattern`StringPatternQ),
	ops:OptionsPattern[]
	]/;!TrueQ[$inMsgFind]:=
	Block[
		{
			$inMsgFind=True,
			res
			},
		res=MsgFind[Evaluate@e, mpat, ops];
		res/;Head[res]=!=MsgFind
		];
MsgFind~SetAttributes~HoldFirst


(* ::Subsubsection::Closed:: *)
(*GetUsage*)


definitionPatternsSimplify[valueSpec_List]:=
	Replace[valueSpec,
		Verbatim[HoldPattern][p___]:>
			(HoldForm[p]/.{
				Verbatim[Pattern][name_,pat_]:>pat,
				Verbatim[Optional][Verbatim[Pattern][name_,pat_],v_]:>Optional[pat,v]
				}),
		1];


defintionsValueFunctions=
	OwnValues|DownValues|UpValues|SubValues|Attributes|Messages|Options;
GetUsage[
	sym_Symbol|Verbatim[HoldPattern][sym_Symbol],
	getTypes:
		(defintionsValueFunctions|
		{defintionsValueFunctions..}|All|Short):Short,
	fullUsage:Full|True|False|Short:False]:=
	With[{
		get=
			Replace[getTypes,
				{
					All->{
						OwnValues,DownValues,UpValues,SubValues,
						Attributes,Messages,Options},
					Short->{OwnValues,DownValues,UpValues,SubValues},
					a:Except[_List]:>{a}
					}],
		full=Replace[fullUsage,{Full->True,Short->False}]
		},
		With[{vals=Join@@Table[With[{a=a},a[sym]],{a,get}]},
			If[full,
				vals,
				First/@vals//definitionPatternsSimplify
				]
			]
		];
GetUsage~SetAttributes~HoldFirst;


formattedUsageOnClick=
	Block[{
		GeneralUtilities`Debugging`PackagePrivate`$DefinitionSymbolTemplateBoxOptions=
			{
				Editable -> False,
				DisplayFunction -> 
					Function[
						TagBox[
							TagBox[
								TooltipBox[#2,
									StyleBox[#,
										FontColor -> RGBColor[0, 0, 0],
										FontFamily -> "Courier", 
										FontWeight -> Bold
										],
									TooltipDelay -> 0.4
									],
								EventHandlerTag[{
									"MouseClicked" :>(
										Replace[ToExpression[#,StandardForm,FormattedDefs],
											c:Column[{__}]:>(
												SelectionMove[EvaluationNotebook[],After,Cell];
												NotebookWrite[EvaluationNotebook[],
													Cell[BoxData@ToBoxes@c,
														Sequence@@Rest@NotebookRead[EvaluationCell[]]
														],
													None,
													AutoScroll->False
													]
											)]
										)
									}]
							],
							MouseAppearanceTag @ "LinkHand"
						]
					],
					InterpretationFunction -> (#&)
				}
			},
			RawBoxes@ToBoxes@GeneralUtilities`CodeForm[#]
			]&;


Options[FormattedUsage]=
	Join[
		{
			Format->formattedUsageOnClick
			},
		Options@Column,
		Options@Style
		];
FormattedUsage[
	sym_Symbol|Verbatim[HoldPattern][sym_Symbol],
	fullUsage:Full|True|False|Short:False,
	ops:OptionsPattern[]]:=
	With[{
		format=
			Replace[OptionValue[Format],{
				None->Identity,
				Automatic|Box->(GeneralUtilities`PrettyForm@#&)
				}]
				},
		format/@(sym~GetUsage~fullUsage)
			//Column[#,FilterRules[{ops},Options@Column]]&
			//Style[#,"Input",FilterRules[{ops},Options@Style]]&
		];
FormattedUsage~SetAttributes~HoldFirst;


FormattedDefs[
	sym_Symbol|Verbatim[HoldPattern][sym_Symbol],
	ops:OptionsPattern[]
	]:=
	FormattedUsage[sym,Full,ops];
FormattedDefs~SetAttributes~HoldFirst;


(* ::Subsubsection::Closed:: *)
(*ToolbarAdd*)


ToolBarEdit[toolbar_,
editFunction_:(Delete[#1,First/@#2]&),
editObjects_:(_Grid|_Row|_Column)
]:=
With[{toolbarCell=FirstCase[FrontEndResource["FEExpressions",toolbar],
_Cell]},
With[{toolbarExpression=ToExpression@First@toolbarCell},
With[{resourceList=
		Replace[
Position[toolbarExpression,editObjects],
pos_List:>Table[p->Part[toolbarExpression,Sequence@@p],{p,pos}]
]
},
ReplacePart[toolbarCell,
1->Replace[editFunction[
toolbarExpression,
resourceList
],
b:Except[_BoxData]:>BoxData@ToBoxes@b
]
]
]
]
]


(* ::Subsubsection::Closed:: *)
(*ContextNotebook*)


usageMSG[s_]:=MessageName[s,"usage"];
usageMSG~SetAttributes~HoldFirst;


ContextOrdering[name_]:=(StringLength[name]+Which[
		MemberQ[ToExpression[name,StandardForm,Attributes],Temporary],
		1000,
		(Length@ToExpression[name,StandardForm,OwnValues]==0&&
			Length@ToExpression[name,StandardForm,DownValues]==0&&
			Length@ToExpression[name,StandardForm,UpValues]==0&&
			Length@ToExpression[name,StandardForm,SubValues]==0),
		500,
		MatchQ[
			ToExpression[name,StandardForm,usageMSG],
			_MessageName
			],100,
		True,
		LetterNumber@StringTake[name,{1}]
		])


ContextFind[pkg_,pat_:"*",ops:(_Rule|_RuleDelayed)...]:=
	DocFind[pat,
		ContextOrdering,
		Context->pkg,
		ops]


ContextNotebook[pkg_]:=With[{nb=OpenDocs[
		"",
		CreateNotebook,
		Visible->False]},
	With[{cells=Prepend[Cell[BoxData@#,"SearchResultCell",
		CellEventActions->{},
		Deletable->True]&/@Cases[DocFind["*",
			ContextOrdering,
			Context->pkg,
			ButtonFunction->((
				NotebookDelete@Cells[nb];
				OpenDocs[#,nb])&)
			],Button[
			Mouseover[Style[text_,___],___],
			cmd___]:>{Cell[
				BoxData@ToBoxes@Button[Mouseover[
					Style[text,RGBColor[.75,0,0]],
					Style[text,RGBColor[.95,.2,0]]
					],
				cmd],
			"SearchResultTitle"],
		Cell[Replace[
			ToExpression["Unevaluated["<>pkg<>"`"<>text<>"]",
				StandardForm,MessageName[#,"usage"]&],{
				_MessageName:>pkg<>"`"<>text,
				b_:>BoxData@b
				}],
		"SearchResultSummary"]
		},
	\[Infinity]],
	Cell[pkg,"SearchPageHeading",CellFrame->{{0,0},{1,0}}]
	]},
	SetOptions[nb,
		DockedCells->
		Replace[
			ToolBarEdit["HelpViewerToolbar",
				BoxData@{ToBoxes@#1,
					ToBoxes@Button[
						Row@{Spacer[25],Style["\[ReturnIndicator]",Gray]},
						SetOptions[#,Deletable->True]&/@Cells@nb;
						NotebookPut[Notebook[cells,AbsoluteOptions@nb],nb];
						SelectionMove[nb,Before,Notebook];
						SetOptions[nb,WindowTitle->"Context: "<>pkg<>"`"],
						Method->"Queued",
						Appearance->"Frameless"
						]}&
				],
			Cell[e_,t_,c__]:>Cell[e,t,
				Background->GrayLevel[.95],
				CellFrame->{{0,0},{5,0}},c]
			]
		];
	NotebookDelete@Cells@nb;
	NotebookWrite[nb,cells,None,AutoScroll->False]];
	SetOptions[nb,WindowTitle->"Context: "<>pkg<>"`",Visible->True];
	nb
	]


(* ::Subsubsection::Closed:: *)
(*Documentation Dialog*)


DocsDialog[dialog:Except[_Rule]:False,ops:OptionsPattern[CreateDialog]]:=
DynamicModule[{
	symbolName="",context="",option="",
	optionUpdate,symbolUpdate,viewing=False,
	autocomplete=True},
	Dynamic[viewing;context;
		{
			Column@{
				TextCell["Context","Text",
					FontSize->If[dialog===DockedCells,12,Automatic]],
				TextCell[
					InputField[
						Dynamic[context,
						(If[
								MemberQ[StringLength/@{#,context},0]
									||
								Not@(StringMatchQ[#,context<>"*"]||StringMatchQ[context,#<>"*"]),
								symbolName="";
								option=""];
								context=#
							)&
						],String],"Input"]},
			Grid[{
				{
					TextCell["Symbol","Text",FontSize->If[dialog===DockedCells,12,Automatic]],
					TextCell["Option","Text",FontSize->If[dialog===DockedCells,12,Automatic]]
				},
				{
					TextCell[
						InputField[
							Dynamic[symbolName,
								(symbolName=#;symbolUpdate=RandomReal[];&)],
							String,
							FieldSize->Automatic
							],
						"Input"],
					TextCell[
						InputField[
							Dynamic[option,
									(If[symbolName=!="",option=#;optionUpdate=RandomReal[];]&)],
							String,
							FieldSize->Automatic],
						"Input"]
					},
					With[{conf=
						{
							FrameStyle->GrayLevel[.8],
							Framed->True,
							Background->White,
							ImageSize->{290,If[dialog===DockedCells,60,250]}}
						},
							{
								Dynamic[symbolName;
									If[StringLength[symbolName]>1,
										If[DownValues@DocFind=={},Needs@"BTools`"];
										DocFind[symbolName,
												Context->If[context=="","*",context],
												Sequence@@conf
											],
										""
										],
									TrackedSymbols:>{symbolName}
									],
								Dynamic[option;
											If[option=!="",
													OpsFind[
														ToExpression[
																If[context=="",symbolName,context<>"`"<>symbolName],
																	StandardForm,Unevaluated],
															option,
															ButtonFunction->Hyperlink,
															Sequence@@conf
														],
													""
												],
									TrackedSymbols:>{option}
									]
								}
							]
						},
						Dividers->{{1->Gray,2->Gray,3->Gray},{1->Gray,-1->Gray}},
						Alignment->{Left,Top}
					]
				}//
					If[dialog===DockedCells,
						Column@{
							Button[
								RawBoxes@
									FrontEndResource["FEBitmaps",
										If[viewing,"SquareMinusIconSmall","SquarePlusIconSmall"]
										],
								viewing=Not@viewing,
								Appearance->"Frameless"
											],
							Row@{
									Spacer[25],
									If[viewing,
										Column@#,
										Button[Style["Search Documentation",Italic,Gray],
											viewing=True,
											Appearance->"Frameless"]
										]
									}
								}&,
							Column],
			TrackedSymbols:>{viewing,context}
		]]//
			If[dialog===DockedCells,
				(#/.(Dividers->_)->(Dividers->None))&,
				TextCell[
					Framed[#,
						RoundingRadius->5,
						Background->GrayLevel[.95]],
					FontFamily->"ArialBlack"]&]//
			Deploy//
				Switch[
					If[
						MatchQ[dialog,
							_NotebookObject?(NotebookInformation[#]===$Failed&)|
							Except[_NotebookObject|True]
							],
						(Length@{ops}>0),
						dialog
					],
					True,CreateDialog[#,ops,WindowTitle->"Documentation Helper"]&,
					_NotebookObject,CreateDialog[#,dialog,Sequence@@Join[{ops},Options@dialog]]&,
					_,Identity];


(* ::Subsubsection::Closed:: *)
(*$DockDocDialog*)


$DockDocDialog:=
	Append[
		First@FEResourceFind["Help*Toolbar"]//Last,
		Cell[
			BoxData@ToBoxes@(
				DocsDialog[DockedCells]/.
					(
						(ImageSize->{290,_})->(ImageSize->{290,{60,250}})
					)
				)]
		]


(* ::Subsection::Closed:: *)
(*End*)


End[];


(* ::Section::Closed:: *)
(*EndPackage*)


EndPackage[]
