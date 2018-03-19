(* ::Package:: *)

(* ::Chapter:: *)
(*FETools*)


(* ::Text:: *)
(*Package of FE related crud*)


BeginPackage["FETools`"]


(* ::Subsubsection::Closed:: *)
(*Tokens / Packets / Values*)


$FETokenList::usage="The loaded lists of FETokens";
RefreshFETokens::usage="Loads the current FETokens";
FETokens::usage="The FE tokens matching a pattern";
FETokenBrowser::usage="A formatter on FETokens";


$FEPacketList::usage="The list of FE packets";
FEPackets::usage="The FE packets matching a pattern";
FEPacketBrowser::"A formatter on FEPackets";
FEPacketExecute::usage="Analagous to FrontEndTokenExecute";


$FEValueList::usage=
	"The list of things known by CurrentValue";
FEValues::usage=
	"The FE values matching a pattern";
FEValueBrowser::usage=
	"The FE values matching a pattern";


FESetMouseAppearance::usage=
	"Sets the mouse appearance";


FEScreenPosition::usage=
	"Gets screen coordinates";
FEScreenPath::usage=
	"Generates a path of screen coordinates relative to one another";


FEMoveMouse::usage=
	"Sets the mouse position";
FEClickMouse::usage=
	"Clicks at a position";
FEDragMouse::usage=
	"Drags the mouse position";


(* ::Subsubsection::Closed:: *)
(*Objects*)


FEParent::usage="Gets the parent";
FEChildren::usage="FEChildren";
FESiblings::usage="FESiblings";
FENextSibling::usage="FENextSibling";
FEPreviousSibling::usage="FEPreviousSibling";


(* ::Subsubsection::Closed:: *)
(*Files*)


FEImport::usage=
	"Attempts to generalize the FE import process";
FEToFileName::usage=
	"Attemps to resolve a file name using FrontEndFiles and InternalFiles";


InternalFiles::usage=
	"Gets internal files matching a pattern";
InternalSystemFiles::usage=
	"Finds SystemFiles that match a pattern";
InternalDocumentationFiles::usage=
	"Finds documentations files";
FrontEndFiles::usage="Tries to find a front end file by a name pattern";
FrontEndFile::usage="Legacy binding to FrontEndFiles";


FrontEndImageFiles::usage="Selects images from FrontEndFiles";
FrontEndImage::usage="Uses FrontEndFile to find image files";
FrontEndImageBrowser::usage="Opens a browser to all the possible FrontEndImages";


FrontEndBlobIcon::usage=
	"Pulls the blob icon for an expression (if it has one)";


(* ::Subsubsection::Closed:: *)
(*Chars*)


FEUnicodeCharBrowser::usage=
	"A little unicode character browser";


(* ::Subsubsection::Closed:: *)
(*Attached cells*)


FEAttachCell::usage="Simplified syntax for attaching a cell";


(* ::Subsubsection::Closed:: *)
(*Notebooks*)


FENotebooks::usage=
	"Gets all notebooks, even the hidden ones";


FEWindowSize::usage=
	"Gives the true window size of a Notebook";
FEScreenShot::usage=
	"Captures a screenshot of a given spec";
FECopyScreen::usage=
	"Copies FEScreenShot";


(* ::Subsubsection::Closed:: *)
(*Boxes*)


FEBoxRef::usage=
	"Formats a FE`BoxReference";
FEBoxObject::usage=
	"Gets the box object FE`BoxReference";
FEBoxRead::usage=
	"Reads the box object FE`BoxReference";
FEBoxReplace::usage=
	"Replaces a FE`BoxReference";
FEBoxEdit::usage=
	"Applies FEReplaceBox to FEReadBox";
FEBoxSelect::usage=
	"Selects the FE`BoxReference";


FEBoxGetOptions::usage=
	"Gets options for a  FE`BoxReference";
FEBoxSetOptions::usage=
	"Set options for a FE`BoxReference";


(* ::Subsubsection::Closed:: *)
(*Autocomplete*)


FEAddAutocompletions::usage=
	"Adds autocompletion data to a pattern";


(* ::Subsubsection::Closed:: *)
(*Hidden Symbols*)


FEHiddenBlock::usage="";
FESetSymbolColoring::usage="";


(* ::Subsubsection::Closed:: *)
(*CopyCells*)


FESelectCells::usage=
	"Selects cells by criterion";


(* ::Subsubsection::Closed:: *)
(*FindFileOnPath*)


FEFindFileOnPath::usage=
	"Safe version of FrontEnd`FindFileOnPath"


(* ::Subsubsection::Closed:: *)
(*UserBaseFile*)


FEUserBaseFile::usage=
	"Locates or copies a system file in $UserBaseDirectory";


(* ::Section:: *)
(*Private*)


Begin["`Private`"];


(* ::Subsection:: *)
(*Resources*)


(* ::Subsubsection::Closed:: *)
(*FETokens/FEPackets*)


{
{
{$FESettings,$FESeeminglyRandom,
$FEDataForms,$FEPacketList},
{$FEBoxForms,$FEInterfaceStuff}
},
$FEData
}=FrontEndExecute@FrontEnd`NeedCurrentFrontEndSymbolsPacket[];
$knownUselessPackets={"","Null"};
FEPackets[pat_:""]:=
	DeleteCases[
		DeleteDuplicates@
			Sort@
				Select[$FEPacketList,StringMatchQ[___~~pat~~___]],
		Alternatives@@$knownUselessPackets
		];


FEPacketBrowser[pat:_String:"",ops___]:=
	Interpretation[
		DynamicModule[{packetArgs=RowBox@{"EvaluationNotebook","[","]"}},
			Column@{
				PaneColumn[
					Button[
						Mouseover[
								Style[#,"Input",FontWeight->Plain],
									Style[#,Purple,"Input",FontWeight->"DemiBold"]
								],
						Replace[
							FrontEndExecute@
								Block[{$Context="FrontEnd`"},
									ToExpression[#][
										Sequence@@Flatten[ToExpression@RowBox@{"{",packetArgs,"}"},1]
										]
									],
							r:Except[Null]:>(
								If[CurrentValue[NextCell@EvaluationCell[],GeneratedCell],
									NotebookDelete@NextCell@EvaluationCell[]
									];
									Print[r]
									)
							];
						Method->"Queued",
						Appearance->"Frameless",
						ImageSize->250,
						Alignment->Left]&/@FEPackets[pat],
					ops
					],
				Style[
					EventHandler[
						InputField[Dynamic[packetArgs],Boxes,
							ImageSize->250],
						{
							"ReturnKeyDown":>
								NotebookWrite[EvaluationNotebook[],"\\"<>"[IndentingNewLine]"],
							{"MenuCommand","HandleShiftReturn"}:>
								Flatten[ToExpression@RowBox@{"{",cellBoxes,"}"},1]
							}
						],
					"Input"
					]
				}//Deploy
		],
	FEPacketSymbol[FEPackets[pat]]
	];
FEPacketSymbol[p:_String|{__String}]:=
	Block[{$Context="FrontEnd`"},ToExpression@p];
FEPacketExecute[
	packet:_Symbol|_String,
	obj:
		_NotebookObject|_CellObject|_BoxObject|_FrontEndObject|
		$FrontEnd|$FrontEndSession|None:$FrontEndSession,
	args___]:=
	With[{psym=If[MatchQ[packet,_String],FEPacketSymbol@packet,packet]},
		FrontEndExecute@
			If[obj===None,
				psym[args],
				psym[obj,args]
				]
			];


$feTokenCache={"AboutBoxDialog", "Above", "AlignBottoms", "AlignCentersHorizontally", "AlignCentersVertically", "AlignLeftSides", "AlignRightSides", "AlignTops", "AllWindowsFront", "BackgroundDialog", "Balance", "Below", "BringToFront", "CellContextDialog", "CellGroup", "CellLabelsToTags", "CellMerge", "CellSplit", "CellTagsEditDialog", "CellTagsEmpty", "CellTagsFind", "CellUngroup", "Clear", "ClearCellOptions", "ClearNoAutoScroll", "Close", "CloseAll", "CloseMain", "ColorSelectorDialog", "ColorsPanel", "CompleteSelection", "Copy", "CopyCell", "CopySpecial", "CreateCounterBoxDialog", "CreateGridBoxDialog", "CreateHyperlinkDialog", "CreateInlineCell", "CreateValueBoxDialog", "Cut", "CycleNotebooksBackward", "CycleNotebooksForward", "DebuggerAbort", "DebuggerClearAllBreakpoints", "DebuggerContinue", "DebuggerContinueToSelection", "DebuggerFinish", "DebuggerResetProfile", "DebuggerShowProfile", "DebuggerStep", "DebuggerStepIn", "DebuggerStepInBody", "DebuggerStepOut", "DebuggerToggleBreakpoint", "DebuggerToggleWatchpoint", "DeleteBibAndNotes", "DeleteBibReference", "DeleteGeneratedCells", "DeleteIndent", "DeleteInvisible", "DeleteNext", "DeleteNextExpression", "DeletePrevious", "DeletePreviousWord", "DistributeBottoms", "DistributeCentersHorizontally", "DistributeCentersVertically", "DistributeLeftSides", "DistributeRightSides", "DistributeSpaceHorizontally", "DistributeSpaceVertically", "DistributeTops", "DuplicatePreviousInput", "DuplicatePreviousOutput", "EditBibNote", "EditStyleDefinitions", "EnterSubsession", "Evaluate", "EvaluateCells", "EvaluateInitialization", "EvaluateNextCell", "EvaluateNotebook", "EvaluatorAbort", "EvaluatorHalt", "EvaluatorInterrupt", "EvaluatorQuit", "EvaluatorStart", "ExitSubsession", "ExpandSelection", "ExpirationDialog", "ExplainBeepDialog", "ExplainColoringDialog", "ExpressionLinewrap", "FileNameDialog", "FindDialog", "FindEvaluatingCell", "FindNextMatch", "FindNextMisspelling", "FindNextWarningColor", "FindPreviousMatch", "FinishNesting", "FixCellHeight", "FixCellWidth", "FontColorDialog", "FontFamilyB", "FontPanel", "FontSizeDialog", "Fraction", "FrontEnd`ButtonNotebook[]", "FrontEnd`EvaluationNotebook[]", "FrontEndHide", "FrontEnd`InputNotebook[]", "FrontEnd`MessagesNotebook[]", "FrontEnd`Private`nb", "FrontEndQuit", "FrontEndQuitNonInteractive", "FrontEndToken[FrontEnd`ButtonNotebook[],\\", ",`distance`]", "GenerateImageCaches", "GenerateNotebook", "GeneratePalette", "GraphicsAlign", "GraphicsBoxOptionsImageSize", "GraphicsCoordinatesDialog", "GraphicsOriginalSize", "GraphicsPlotRangeAll", "GraphicsPlotRangeAutomatic", "GraphicsPlotRangeFixed", "GraphicsRender", "Group", "HandleShiftReturn", "HeadersFootersDialog", "HelpDialog", "HyperlinkGo", "HyperlinkGoBack", "HyperlinkGoForward", "ImageToAutomatic", "ImageToBinary", "ImageToBit", "ImageToBit16", "ImageToByte", "ImageToCMYK", "ImageToggleAlphaChannel", "ImageToggleInterleaving", "ImageToGrayscale", "ImageToHSB", "ImageToReal", "ImageToReal32", "ImageToRGB", "Import", "ImportPictures", "ImportStyleDefinitions", "Indent", "InsertBibAndNotes", "InsertBibNote", "InsertBibReference", "InsertClipPlane", "InsertMatchingBraces", "InsertMatchingBrackets", "InsertMatchingParentheses", "InsertNewGraphic", "InsertObject", "InsertRawExpression", "InsertSoftReturn", "InsertSplitBreak", "LicAuthFailureDialog", "Linebreak", "MacintoshOpenDeskAccessory", "MakeSelectionNotSpan", "MakeSelectionSpan", "MenuListBoxFormFormatTypes", "MenuListCellEvaluators", "MenuListCellTags", "MenuListCommonDefaultFormatTypesInput", "MenuListCommonDefaultFormatTypesInputInline", "MenuListCommonDefaultFormatTypesOutput", "MenuListCommonDefaultFormatTypesOutputInline", "MenuListCommonDefaultFormatTypesText", "MenuListCommonDefaultFormatTypesTextInline", "MenuListConvertFormatTypes", "MenuListDisplayAsFormatTypes", "MenuListExportClipboardSpecial", "MenuListFonts", "MenuListFontSubstitutions", "MenuListGlobalEvaluators", "MenuListHelpWindows", "MenuListNotebookEvaluators", "MenuListNotebooksMenu", "MenuListPackageWindows", "MenuListPalettesMenu", "MenuListPaletteWindows", "MenuListPlayerWindows", "MenuListPlugInCommands", "MenuListPrintingStyleEnvironments", "MenuListQuitEvaluators", "MenuListRelatedFilesMenu", "MenuListSaveClipboardSpecial", "MenuListScreenStyleEnvironments", "MenuListStartEvaluators", "MenuListStyleDefinitions", "MenuListStyles", "MenuListStylesheetWindows", "MenuListTextWindows", "MenuListWindows", "ModifyBoxFormFormatTypes", "ModifyDefaultFontProperties", "ModifyEvaluatorNames", "ModifyFontSubstitutions", "ModifyNotebooksMenu", "ModifyRelatedFiles", "MoveBackward", "MoveExpressionEnd", "MoveForward", "MoveLineBeginning", "MoveLineEnd", "MoveNext", "MoveNextCell", "MoveNextExpression", "MoveNextLine", "MoveNextPlaceHolder", "MoveNextWord", "MovePrevious", "MovePreviousExpression", "MovePreviousLine", "MovePreviousPlaceHolder", "MovePreviousWord", "MoveToBack", "MoveToFront", "New", "NewCDFNotebook", "NewColumn", "NewPackage", "NewRow", "NewText", "NextFunctionTemplate", "NotebookMail", "NotebookMailSelection", "NotebookOneNote", "NotebookOneNoteSelection", "NotebookStatisticsDialog", "NudgeDown", "NudgeLeft", "NudgeRight", "NudgeUp", "Open", "OpenCloseGroup", "OpenFromNotebooksMenu", "OpenFromNotebooksMenuEmpty", "OpenFromPalettesMenu", "OpenFromRelatedFilesMenu", "OpenHelpLink", "OpenSelection", "OpenSelectionParents", "OpenURL", "OptionsDialog", "Otherscript", "PasswordDialog", "Paste", "PasteApply", "PasteApplyNoAutoScroll", "PasteDiscard", "PasteDiscardNoAutoScroll", "PasteSpecial", "Placeholder", "PlainFont", "PreferencesDialog", "PreviousFunctionTemplate", "PrintDialog", "PrintOptionsDialog", "PrintSelectionDialog", "PublishToPlayer", "Radical", "RebuildBibAndNotes", "RebuildHelpIndex", "RecordSoundDialog", "RefreshDynamicObjects", "RelatedFilesMenu", "RemoveAdjustments", "RemoveFromEvaluationQueue", "Replace", "ReplaceAll", "ReplaceFind", "ReplaceParent", "ResetDefaultsText", "ReverseQuote", "Revert", "RunColorDialog", "RunEdgeColorDialog", "RunFaceColorDialog", "Save", "SaveRename", "SaveRenameSpecial", "ScrollLineDown", "ScrollLineUp", "ScrollNotebookEnd", "ScrollNotebookStart", "ScrollPageBottom", "ScrollPageDown", "ScrollPageFirst", "ScrollPageLast", "ScrollPageNext", "ScrollPagePrevious", "ScrollPageTop", "ScrollPageUp", "SelectAll", "SelectGeneratedCells", "SelectionAnimate", "SelectionBrace", "SelectionBracket", "SelectionCloseAllGroups", "SelectionCloseUnselectedCells", "SelectionConvert", "SelectionConvertB", "SelectionDisplayAs", "SelectionDisplayAsB", "SelectionHelpDialog", "SelectionOpenAllGroups", "SelectionParenthesize", "SelectionSaveSpecial", "SelectionScroll", "SelectionSetFind", "SelectionSpeak", "SelectionSpeakSummary", "SelectionUnbracket", "SelectLineBeginning", "SelectLineEnd", "SelectNext", "SelectNextExpression", "SelectNextLine", "SelectNextWord", "SelectNotebookWindow", "SelectPrevious", "SelectPreviousExpression", "SelectPreviousLine", "SelectPreviousWord", "ServerText", "SetCitationStyle", "SetDefaultGraphic", "ShortNameDelimiter", "SimilarCellBelow", "SoundPlay", "SpellCheckerDialog", "StackWindows", "Style", "StyleDefinitionsOther", "StyleOther", "Subscript", "SubsessionEvaluateCells", "Superscript", "SystemPrintOptionsDialog", "Tab", "TemplateSelection", "TestEvaluateNotebook", "TileWindowsTall", "TileWindowsWide", "ToggleAlignmentGuides", "ToggleDebugFlag", "ToggleDynamicUpdating", "ToggleGrayBox", "ToggleOptionListElement", "ToggleShowExpression", "ToggleTestingFlag", "TrustNotebook", "Undo", "Ungroup", "WelcomeDialog", "WindowMiniaturize", "XInfoDialog", "ZoomWindow", "$CellContext`inputnb$$", "$CellContext`sourceNotebook$$", "*.nb", "*.tr", "SystemFiles", "FrontEnd", "StyleSheets", "TextResources", "SystemResources", "Text", "FrontEndToken[", "[", "]", "FrontEnd`*", "FE`*", "FrontEnd`*`*", "FE`*`*", "FrontEndToken[\\", "\\", "Item[", "Item[KeyEvent[", "],", "Name", "vladimir", "\\n", "FontWeight", "FontSlant", "FontVariationsUnderline", "FontSize", "CellFrame", "WholeCellGroupOpener", "CellFrameColor", "ShowGroupOpener", "Background", "ClearCropMarker", "ClearMaskMarkers", "ClearMultiSelMarkers", "ClearPixelPointMarkers", "FindExpression", "GlobalPreferences", "LicenseAgreementDialog", "NotebookSecurity", "OpenCloudObject", "SelectNextCell", "SelectPreviousCell", "WolframCloudLogout", "HeldExpressions", "\","};
$FETokenList:=(
	Replace[$feTokenCache,
		Except[_List]:>RefreshFETokens[]
		];
	$feTokenCache);
RefreshFETokens[]:=
	($feTokenCache=
		DeleteDuplicates@
			StringCases[
				Import@
					URLRead["http://mathematica.stackexchange.com/questions/2572"],
	s:("\""~~Shortest[Except[WhitespaceCharacter]..]~~"\""):>StringTrim[s,"\""]]);
FETokens[pat_:""]:=
Cases[$FETokenList,
_?(StringMatchQ[#,___~~pat~~___]&)
];


FETokenBrowser[pat:_String:"",ops___]:=
	PaneColumn[
		Button[
			Mouseover[
				Style[#,"Input",FontWeight->Plain],
					Style[#,Purple,"Input",FontWeight->"DemiBold"]
				],
			Replace[
				FrontEndTokenExecute[EvaluationNotebook[],#],
				r:Except[Null]:>(
					If[CurrentValue[NextCell@EvaluationCell[],GeneratedCell],
						NotebookDelete@NextCell@EvaluationCell[]
						];
						Print[r]
						)
				];
			Method->"Queued",
			Appearance->"Frameless",
			ImageSize->250,
			Alignment->Left]&/@FETokens[pat],
		ops
		]//Deploy;





(* ::Subsubsection::Closed:: *)
(*Packet usages*)


FESetMouseAppearance[obj_]:=
	FEPacketExecute[
		"SetMouseAppearance",
	None,
		obj
		]


FEScreenPosition[{x_,y_},anchorPosition:None|Automatic|{_,_}:None]:=
	{
		Replace[x,{
			Scaled[i_]:>
				i*(#[[1,2]]-#[[1,1]]&)@CurrentValue[$FrontEndSession,ScreenRectangle],
			Left:>
				CurrentValue[$FrontEndSession,ScreenRectangle][[1,1]],
			Right:>
				CurrentValue[$FrontEndSession,ScreenRectangle][[1,2]],
			Center:>
				(#[[1,1]]+(#[[1,2]]-#[[1,1]])/2&)@
					CurrentValue[$FrontEndSession,ScreenRectangle]
					}
			],
		Replace[y,{
				Scaled[j_]:>
					j*(#[[2,2]]-#[[2,1]]&)@CurrentValue[$FrontEndSession,ScreenRectangle]
				Bottom:>
					CurrentValue[$FrontEndSession,ScreenRectangle][[2,1]],
				Top:>
					CurrentValue[$FrontEndSession,ScreenRectangle][[2,2]],
				Center:>
					(#[[2,1]]+(#[[2,2]]-#[[2,1]])/2&)@
						CurrentValue[$FrontEndSession,ScreenRectangle]
				}]
		}+
		Replace[anchorPosition,{
			None->{0,0},
			Automatic:>MousePosition[]
			}];
FEScreenPosition[pos:_?NumericQ|Scaled|_Symbol]:=
	FEScreenPosition[
		Replace[pos,{
			Left:>{Left,Last@MousePosition[]},
			Right:>{Right,Last@MousePosition[]},
			Top:>{First@MousePosition[],Top},
			Bottom:>{First@MousePosition[],Bottom},
			Center->{Center,Center},
			e:Except[_List]:>{e,e}
			}],
		None];
FEScreenPath[
	crds:({_,_}|_Symbol|_?NumericQ)..,
	anchor:("Anchor"->(Automatic|None|{_,_})):("Anchor"->None)]:=
	Rest@
		FoldList[FEScreenPosition[#2,#]&,Last@anchor,{crds}];


FEMoveMouse[crds__]:=
	Replace[FEScreenPosition[crds],{
		c:{_,_}:>
			FEPacketExecute["SimulateMouseMove",c],
		_->$Failed
		}];
FEMoveMouse[]:=
	FEMoveMouse[{0,0},Automatic]


FEClickMouse[crds__]:=
	Replace[FEScreenPosition[crds],{
		c:{_,_}:>
			FEPacketExecute["SimulateMouseClick",c],
		_->$Failed
		}];
FEClickMouse[]:=
	FEClickMouse[{0,0},Automatic]


FEDragMouse[crds__]:=
	Replace[FEScreenPath[crds],{
		c:{{_,_}..}:>
			FEPacketExecute["SimulateMouseDrag",c],
		_->$Failed
		}];
FEDragMouse[]:=
	FEDragMouse[{10,0},{-10,0},Automatic]


(* ::Subsubsection::Closed:: *)
(*Object*)


FEParent[obj,n]~addUsage~
	"Gets the nth parent object of obj";
FEParent[
	obj:_NotebookObject|_CellObject|_BoxObject,
	n:_Integer?Positive:1
	]:=
	Nest[
		Replace[FrontEndExecute@FrontEnd`ParentObject[#],
			$Failed:>
				FirstCase[
					FrontEndExecute/@{
						FrontEnd`ParentBox[#],
						FrontEnd`ParentCell[#],
						FrontEnd`ParentNotebook[#]
						},
					_NotebookObject|_CellObject|_BoxObject,
					$FrontEnd
					]
			]&,
		obj,
		n
		];


FEChildren[obj,n]~addUsage~
	"Gets the association of object children for obj to depth n";
FEChildren[
	obj:_FrontEndObject|_NotebookObject|_CellObject|_BoxObject,
	n:_Integer?Positive:1
	]:=
	If[n>1,
		Flatten@
			Nest[
				ReplaceAll[
					o:_NotebookObject|_CellObject|_BoxObject:>
						o->FrontEndExecute@FrontEnd`ObjectChildren[o]
					],
				obj,
				n
				],
		FrontEndExecute@FrontEnd`ObjectChildren[obj]
		];


FENextSibling[obj:_NotebookObject|_CellObject|_BoxObject,
	n:_Integer?Positive:1]:=
	Nest[
		FrontEndExecute@*FrontEnd`NextSiblingObject,
		obj,
		n
		];
FEPreviousSibling[
	obj:_NotebookObject|_CellObject|_BoxObject,
	n:_Integer?Positive:1]:=
	Nest[
		FrontEndExecute@*FrontEnd`PreviousSiblingObject,
		obj,
		n
		];


FESiblings[obj:_NotebookObject|_CellObject|_BoxObject]:=
	Replace[FEParent[obj],{
		o:Except[$Failed]:>
			DeleteCases[FEChildren[o],obj]
			}]


(* ::Subsubsection::Closed:: *)
(*CurrentValues*)


$FEValueList=
	{
		"NotebookBrowseDirectory","NotebookPath","PalettePath",
		"AutoOpenPalettes","AutoOpenNotebooks","AutoOpenPaclets",
		"StyleSheetPath","DefaultNotebook","DefaultStyleDefinitions",
		"DefaultPackageStyleDefinitions","DefaultScriptStyleDefinitions","HomePage",
		"ReferenceSystemApplication","SystemConsoleApplication","WebNotebooksDirectory",
		"WolframCloudBaseUrl","PreferencesPath","ConfigurationPath",
		"SystemHelpPath","AddOnHelpPath","AutoloadPath",
		"SpellingDictionariesPath","CharacterEncodingsPath","ConvertersPath",
		"ImportAutoReplacements","ExportAutoReplacements","Language",
		"ExternalDataCharacterEncoding","AllowDownloads","AllowDocumentationUpdates",
		"AllowDataUpdates","AutomaticWolframCloudLogin","AllowExternalChannelFunctions",
		"WolframId","Default2DTool","Default3DTool",
		"MultilaunchWarning","FrontEndEventActions","FrontEndDynamicExpression",
		"ScreenRectangle","ScreenInformation","FrontEndStackSize",
		"BoxFormattingRecursionLimit","NotebookEvaluateRecursionLimit","CaseSensitiveCommandCompletion",
		"VersionedPreferences","VersionedOptions","EvaluatorStartup",
		"DefaultControlPlacement","EvaluationQueueActions","EvaluatorNames",
		"NotebooksMenu","NotebooksMenuHistoryLength","PalettesMenuSettings",
		"FontSubstitutions","Dictionaries","DefaultFontProperties",
		"BoxFormFormatTypes","MessageOptions","NotebookAutoSave",
		"ClosingAutoSave","ClosingSaveDialog","CloseOnClickOutside",
		"IncludeFileExtension","FileChangeProtection","TransitionEffect",
		"TransitionDirection","TransitionDuration","RasterExploreViewRange",
		"MarkerLineThickness","MarkerAspectRatio","AutoGeneratedPackage",
		"Editable","Saveable","StyleEnvironment",
		"ScreenStyleEnvironment","PrintingStyleEnvironment","ShowPageBreaks",
		"WindowToolbars","RulerUnits","BlinkingCellInsertionPoint",
		"CellInsertionPointColor","CellInsertionPointCell","Evaluator",
		"EvaluationCompletionAction","PrintAction","OutputAutoOverwrite",
		"InitializationCellEvaluation","InitializationCellWarning","GlobalInitializationCellWarning",
		"NotebookEventActions","NotebookDynamicExpression","ClearEvaluationQueueOnKernelQuit",
		"Selectable","Clickable","Deletable",
		"CellGrouping","PageWidth","WindowSize",
		"WindowMargins","WindowFrame","WindowElements",
		"WindowFrameElements","WindowFloating","WindowClickSelect",
		"WindowMovable","WindowPersistentStyles","BackgroundAppearance",
		"BackgroundAppearanceOptions","WindowTitle","WindowStatusArea",
		"WindowOpacity","Visible","DockedCells",
		"ControlsRendering","PrintingCopies","PrintingStartingPageNumber",
		"PrintingPageRange","PageHeaders","PageFooters",
		"PageHeaderLines","PageFooterLines","CellFrame",
		"CellDingbat","ShowCellBracket","ShowSelection",
		"ShowGroupOpener","WholeCellGroupOpener","GroupOpenerInsideFrame",
		"ShowClosedCellArea","ShowShortBoxForm","CellMargins",
		"GroupOpenerColor","Deployed","Enabled",
		"CellEditDuplicate","CellEditDuplicateMakesCopy","ReturnCreatesNewCell",
		"StyleKeyMapping","CellSplitCopiesTags","Evaluatable",
		"EvaluationMode","Copyable","CellOpen",
		"CellGroupingRules","AllowGroupClose","AllowReverseGroupClose",
		"ConversionRules","TaggingRules","CreateCellID",
		"TextClipboardType","StripStyleOnPaste","CellHorizontalScrolling",
		"SpeechNavigation","DataCompression","PageBreakAbove",
		"PageBreakWithin","PageBreakBelow","GroupPageBreakWithin",
		"OutputSizeLimit","CellContext","CellProlog",
		"CellEpilog","CellEvaluationFunction","AllowDebugging",
		"DynamicUpdating","VariableChangesAreEdits","MaintainDynamicCaches",
		"InitializationCell","InitializationGroup","CellEvaluationDuplicate",
		"GeneratedCell","CellAutoOverwrite","GenerateImageCachesOnPlacement",
		"LegacyGraphicsCompatibility","PreserveOldOutputGraphicsAttributes","CellEventActions",
		"CellDynamicExpression","DynamicEvaluationTimeout","TemporaryControlActiveInterval",
		"PrivateEvaluationOptions","ShowCellLabel","CellLabelStyle",
		"CellLabelPositioning","CellLabelAutoDelete","CellLabelMargins",
		"CellFrameMargins","CellFrameColor","CellFrameStyle",
		"CellFrameLabels","CellFrameLabelMargins","ShowCellTags",
		"CellSize","CellBaseline","DefaultNewCellStyle",
		"DefaultNewInlineCellStyle","DefaultDuplicateCellStyle","DefaultReturnCreatedCellStyle",
		"DefaultFormatType","DefaultInlineFormatType","DefaultDockedCellStyle",
		"DefaultAttachedCellStyle","AutoIndent","InputAliases",
		"InputAutoReplacements","ContextMenu","ComponentwiseContextMenu",
		"CellChangeTimes","TrackCellChangeTimes","CellChangeTimeMergeInterval",
		"DelimiterFlashTime","ShowCursorTracker","MousePointerAppearance",
		"ShowAutoStyles","ShowCodeAssist","ShowAutoConvert",
		"ShowAutoSpellCheck","IgnoreSpellCheck","ShowMissingStyles",
		"ShowPredictiveInterface","ShowSyntaxStyles","EmphasizeSyntaxErrors",
		"StructuredSelection","StyleBoxAutoDelete","DragAndDrop",
		"ShowSpecialCharacters","AllowInlineCells","PasteBoxFormInlineCells",
		"TextAlignment","TextJustification","Hyphenation",
		"TabFilling","LineSpacing","ParagraphSpacing",
		"ParagraphIndent","TabSpacings","AutoItalicWords",
		"AutoStyleWords","AutoQuoteCharacters","PasteAutoQuoteCharacters",
		"LanguageCategory","DefaultNaturalLanguage","StyleHints",
		"FormatType","AutoSpacing","ShowContents",
		"ScriptSizeMultipliers","ImageSizeMultipliers","ScriptMinSize",
		"ScriptBaselineShifts","ScriptLevel","ShowStringCharacters",
		"NumberMarks","PrintPrecision","AutoNumberFormatting",
		"AutoMultiplicationSymbol","DigitBlock","DigitBlockMinimum",
		"NumberPoint","NumberSeparator","NumberMultiplier",
		"LimitsPositioningTokens","SingleLetterItalics","MultiLetterItalics",
		"SingleLetterStyle","MultiLetterStyle","LowerCaseStyle",
		"GreekStyle","TraditionalFunctionNotation","DelimiterMatching",
		"ZeroWidthTimes","SpanMinSize","SpanMaxSize",
		"SpanSymmetric","SpanLineThickness","SpanCharacterRounding",
		"SpanAdjustments","LineBreakWithin","LineIndent",
		"LineIndentMaxFraction","LinebreakAdjustments","LinebreakSemicolonWeighting",
		"CounterIncrements","CounterAssignments","AspectRatioFixed",
		"ImageSize","ImageMargins","ImageRegion",
		"SpeedOfTime","AnimationRunning","AnimationDisplayTime",
		"AnimationCycleOffset","AnimationCycleRepetitions","DefaultNewGraphics",
		"DefaultNewInlineGraphics","DefaultNewGraphics3D","DefaultNewInlineGraphics3D",
		"CacheGraphics","Antialiasing","Lighting",
		"ClipPlanes","ClipPlanesStyle","FillForm",
		"MenuSortingValue","MenuCommandKey","StyleMenuListing",
		"CounterStyleMenuListing","FormatTypeAutoConvert","VirtualGroupData",
		"FontFamily","FontSize","FontWeight",
		"FontSlant","FontTracking","Magnification",
		"FontColor","FontOpacity","Background",
		"ShowInvisibleCharacters","ShowDiscretionaryLineSeparators","StyleBoxOptions",
		"GeometricTransformationBoxOptions","GeometricTransformation3DBoxOptions","Enabled",
		"Background","ImageSize","ImageMargins",
		"Evaluator","StripOnInput","Enabled",
		"Background","ImageSize","ImageMargins",
		"AnimationRunning","Enabled","Background",
		"ImageSize","ImageMargins","Evaluator",
		"Active","Enabled","Background",
		"ImageMargins","Enabled","Background",
		"ImageSize","ImageMargins","Enabled",
		"Background","Evaluator","Selectable",
		"Enabled","Background","Evaluator",
		"Selectable","Enabled","Background",
		"Evaluator","Selectable","Enabled",
		"Background","ImageSize","ImageMargins",
		"StripOnInput","Editable","Selectable",
		"Enabled","Background","ImageSize",
		"ImageMargins","Editable","Selectable",
		"Background","StripOnInput","Enabled",
		"Background","ImageSize","ImageMargins",
		"ScrollPosition","Enabled","Background",
		"ImageSize","ImageMargins","Editable",
		"Selectable","Enabled","Background",
		"ImageMargins","Background","ImageSize",
		"ImageMargins","Enabled","Background",
		"ImageSize","ImageMargins","StripOnInput",
		"ScrollPosition","Enabled","Background",
		"ImageSize","ImageMargins","StripOnInput",
		"Background","ImageSize","ImageMargins",
		"TransitionDirection","TransitionDuration","TransitionEffect",
		"Enabled","Background","ImageSize",
		"ImageMargins","Enabled","Background",
		"ImageSize","ImageMargins","Enabled",
		"Background","ImageMargins","Enabled",
		"Background","ImageSize","ImageMargins",
		"Enabled","Background","ImageSize",
		"ImageMargins","Enabled","Background",
		"ImageSize","ImageMargins","Enabled",
		"Background","ImageSize","ImageMargins",
		"ScrollPosition","Enabled","Background",
		"ImageSize","ImageMargins","Editable",
		"Selectable","Editable","Selectable",
		"Enabled","Background","ImageSize",
		"ImageMargins","Background","StripOnInput",
		"Background","Enabled","ImageSize",
		"ImageMargins","Background","FormatType",
		"ImageMargins","ImageSize","Background",
		"FormatType","ImageMargins","ImageSize",
		"ClipPlanes","ClipPlanesStyle","Lighting",
		"Background","FormatType","Background",
		"FormatType","Background","FormatType"
		};


FEValues[pat_:""]:=
	DeleteDuplicates@
		Sort@
			Select[$FEValueList,StringMatchQ[___~~pat~~___]];
FEValueBrowser[pat:_String:"",ops___]:=
	DynamicModule[{packetArgs=RowBox@{""}},
		Column@{
			PaneColumn[
				Button[
					Mouseover[
							Style[#,"Input",FontWeight->Plain],
								Style[#,Purple,"Input",FontWeight->"DemiBold"]
							],
					Replace[
						CurrentValue@@
							Append[
								Sequence@@Flatten[
									ToExpression@RowBox@{"{",packetArgs,"}"},
									1],
								#
								],
						r:Except[Null|$Failed]:>(
							If[CurrentValue[NextCell@EvaluationCell[],GeneratedCell],
								NotebookDelete@NextCell@EvaluationCell[]
								];
								Print[r]
								)
						];
					Method->"Queued",
					Appearance->"Frameless",
					ImageSize->250,
					Alignment->Left]&/@FEValues[pat],
				ops
				],
			Style[
				EventHandler[
					InputField[Dynamic[packetArgs],Boxes,
						ImageSize->250],
					{
						"ReturnKeyDown":>
							NotebookWrite[EvaluationNotebook[],"\\"<>"[IndentingNewLine]"],
						{"MenuCommand","HandleShiftReturn"}:>
							Flatten[ToExpression@RowBox@{"{",packetArgs,"}"},1]
						}
					],
				"Input"
				]
			}//Deploy
	];


(* ::Subsubsection::Closed:: *)
(*FEFiles*)


InternalFiles[namePattern_,directoryExtensions___String,depth:_Integer|\[Infinity]:\[Infinity]]:=
	FileNames[namePattern,
		FileNameJoin@{
			$InstallationDirectory,
			directoryExtensions
			},
		depth];
InternalDocumentationFiles[namePattern_,args___]:=
	InternalFiles[namePattern,"Documentation",args];
InternalSystemFiles[namePattern_,args___]:=
	InternalFiles[namePattern,"SystemFiles",args];
FrontEndFiles[namePattern_,args___]:=
	InternalSystemFiles[namePattern,"FrontEnd",args];


$FrontEndDirectory=
	FileNameJoin@{
		$InstallationDirectory,
		"SystemFiles",
		"FrontEnd"
		};


FrontEndFile=FrontEndFiles;


FrontEndImageFiles[files_List]:=
	Select[files,feImageQ];
FrontEndImageFiles[pattern_,specs___String,
	function:
		InternalFiles|
		InternalSystemFiles|
		FrontEndFiles:
		FrontEndFiles]:=
	FrontEndImageFiles@function[pattern,specs];
FrontEndImage[name_,which_:First]:=
With[{files=Select[FrontEndFiles[name],feImageQ]},
Switch[which,
All,Thread[files->(Import/@files)],
_Symbol,Thread[which@files->(Import@which@files)],
_,Replace[Thread[Flatten@{files[[which]]}->(Import/@Flatten@{files[[which]]})],
{img_}:>img
]
]
]


FrontEndImageBrowser[pattern_,
	args:Except[_Rule|_RuleDelayed]...,
	ops:OptionsPattern[Options@PaneColumn]]:=
	PaneColumn[
		With[{img=Quiet@Check[Import@#,$Failed]},
			Button[
			Tooltip[img,#],
			Print@(#->img),
			Appearance->"Frameless"]
			]&/@
			FrontEndImageFiles[
				Replace[pattern,{
					Verbatim[Verbatim][p_]:>p,
					(StartOfString~~p_):>(p~~___),
					(p_~~EndOfString):>(___~~p),
					p_:>(___~~p~~___)
					}],args],
		ops]


FrontEndBlobIcon[expr_,fmt_:StandardForm]:=
	With[{boxes=MakeBoxes[expr,fmt]},
		If[
			MatchQ[boxes,
				InterpretationBox[_RowBox,___]|
				TagBox[TemplateBox[{_RowBox,___},___],___]
				],
			ToExpression@
				FirstCase[
					boxes,
					PaneSelectorBox[{False->GridBox[{{_,e_,___},___},___],___},___]:>e,
					"None",
					\[Infinity]
					],
			None
			]
		]


TRFiles[pat_]:=
	FileNames[
	"*.tr",
		FileNameJoin@{
			$InstallationDirectory,
			"SystemFiles",
			"FrontEnd",
			"TextResources"
			}
		]


(* ::Subsubsection::Closed:: *)
(*Characters*)


$FEUnicodeChars:=
	$FEUnicodeChars=
		Select[StringContainsQ["Characters"]]@
			InternalFiles["*.nb",
				"Documentation","English",
					"System","ReferencePages",
					"Characters"]//Map[FileBaseName];


FEUnicodeCharFind[pat_:_]:=
	Select[$FEUnicodeChars,
		StringContainsQ[pat]
		];
FEUnicodeCharBrowser[pat_:_]:=
	Replace[FEUnicodeCharFind[pat],{
		s:{__}:>HyperlinkBrowse[
			TemplateApply["\"\[``]\"",#]->
				ToExpression[TemplateApply["\"\[``]\"",#],
					StandardForm
					]&/@s,
			Print,
			ImageSize->{250,250}
			],
		_->None
		}];


(* ::Subsubsection::Closed:: *)
(*FEImport*)


feImageFormats=ToLowerCase/@Image`$ImportImageFormats;
feImageQ[s_String]:=
	MemberQ[feImageFormats,FileExtension@s];


FEImport[f_String?FileExistsQ]:=
	Import[f];
FEImport[f:FrontEnd`FileName[_,s_?feImageQ,ops___]]:=
	FE`Evaluate@FEPrivate`ImportImage[f]
FEImport[f:FrontEnd`FileName[_,_,ops___]]:=
	Import[FEToFileName[f],ops];
FEImport[FEPrivate`FrontEndResource[r___]]:=
	FrontEndResource[r]


FEToFileName[FrontEnd`FileName[p:{__},f_,___]]:=
	Replace[
		Select[FrontEndFiles[f],
			StringContainsQ@
				FileNameJoin@p
			],{
			{}:>
				Replace[
					Select[InternalFiles[f],
						StringContainsQ@
							FileNameJoin@p
					],
					{fn_}:>fn
					],
			{fn_}:>fn
		}];
FEToFileName[FrontEnd`ToFileName[a___]]:=
	FEToFileName[FrontEnd`FileName[a]];


(* ::Subsubsection::Closed:: *)
(*FileOnPath*)


$FEPathMap=
	Thread/@
		{
			{"StyleSheets","StyleSheet","StyleSheetPath"}->
				"StyleSheetPath",
			{"Palettes","Palette","PalettePath"}->
				"PalettePath",
			{"TextResources","TextResource",
				"PrivatePathsTextResources"}->
				"PrivatePathsTextResources",
			{"SystemResources","SystemResource",
				"PrivatePathsSystemResources"}->
				"PrivatePathsSystemResources",
				{"AFM","PrivatePathsAFM"}->"PrivatePathsAFM",
			{
				"AutoCompletionData",
				"PrivatePathsAutoCompletionData"
				}->
					"PrivatePathsAutoCompletionData",
			{"Bitmaps","Bitmap","PrivatePathsBitmaps"}->
				"PrivatePathsBitmaps",
			{"Fonts","Font","PrivatePathsFonts"}->
				"PrivatePathsFonts",
			{"TranslationData","PrivatePathsTranslationData"}->
				"PrivatePathsTranslationData",
			"AddOnHelp"->"AddOnHelpPath",
			"Autoload"->"AutoloadPath",
			{"CharacterEncoding","CharacterEncodings"}->
				"CharacterEncodingsPath",
			"Configuration"->"ConfigurationPath",
			{"Converter","Converters"}->"ConvertersPath",
			"Notebook"->"NotebookPath",
			"Preferences"->"PreferencesPath",
			"SpellingDictionaries"->"SpellingDictionariesPath",
			"SystemHelp"->"SystemHelpPath",
			{"Trusted","TrustedPath"}->
				"NotebookSecurityOptionsTrustedPath",
			{"Untrusted","UntrustedPath"}->
				"NotebookSecurityOptionsUntrustedPath"
			}//Flatten//Association;


FEFindFileOnPath//Clear


Options[FEFindFileOnPath]=
	{
		"ReturnPath"->False,
		"SelectFirst"->True
		};
Options[iFEFindFileOnPath]=
	Options@FEFindFileOnPath;
iFEFindFileOnPath[
	file_,
	path:{__String?(KeyMemberQ[$FEPathMap,#]&)},
	ops:OptionsPattern[]
	]:=
	Replace[{
		{_,{}}->$Failed,
		{_,{e_}}:>
			If[OptionValue@"SelectFirst"//TrueQ,
				First@e,
				e
				]
		}]@
	Reap@
		Catch@
			Map[
				Replace[
					FrontEndExecute@
						FrontEnd`FindFileOnPath[
							Switch[file,
								_FileName|_FrontEnd`FileName,
									ToFileName[file],
								_List,
									FileNameJoin@file,
								_File,
									First[file],
								_String,
									file,
								_,
									Throw@$Failed
								],
							#
							],
					s:Except[$Failed]:>
						CompoundExpression[
							Sow@
								If[OptionValue@"ReturnPath"//TrueQ,
									#->s,
									s
									],
							If[OptionValue@"SelectFirst",Throw[Break]]
							]
					]&,
				Flatten@Lookup[$FEPathMap,path]
				];
FEFindFileOnPath[
	file_,
	path:{__String?(KeyMemberQ[$FEPathMap,#]&)},
	exts:
		{__String?(StringLength[#]<6&&StringMatchQ[#, WordCharacter..]&)}:
		{"nb", "tr", "m"},
	ops:OptionsPattern[]
	]:=
	Replace[iFEFindFileOnPath[file, path, ops],
		$Failed:>
			Replace[Null->$Failed]@
				Catch@
					Scan[
						Replace[e:Except[$Failed]:>Throw[e]]@
							iFEFindFileOnPath[file<>"."<>#, path, ops]&,
						exts
						]
		];
FEFindFileOnPath[file_,
	path:_String|Automatic:Automatic,
	exts:
		{__String?(StringLength[#]<6&&StringMatchQ[#, WordCharacter..]&)}:
		{"nb", "tr", "m"},
	ops:OptionsPattern[]
	]:=
	FEFindFileOnPath[
		file,
		Replace[path, 
			{
				Automatic:>Keys@DeleteDuplicates@$FEPathMap,
				s_String:>{s}
				}
			],
		exts,
		ops
		];


(*$FEPathMapSpecial=
	<|
		"ImportFormat"->
			Function[{
				FileNameJoin@{"SystemFiles",#,"Import.m"}
		|>;*)


(*FEFindFileOnPath[
	file_,
	"Format"
	]*)


(* ::Subsubsection::Closed:: *)
(*UserBaseCopy*)


Options[FEUserBaseFile]=
	{
		AutoCopy->False
		};
FEUserBaseFile[
	fName_,
	fep:
		{
			__String?(KeyMemberQ[$FEPathMap,#]&)
			}|
			_String|Automatic:Automatic,
	exts:
		{__String?(StringLength[#]<6&&StringMatchQ[#, WordCharacter..]&)}:
		{"nb", "m", "tr"}
	]:=
	Module[
		{
			res=FEFindFileOnPath[fName, fep, exts, "ReturnKey"->True],
			path,
			heads,
			file,
			fileNew,
			autocopy=TrueQ@OptionValue[AutoCopy]
			},
		If[res=!=$Failed,
			path=res[[1]];
			path=
				DeleteCases[{StringJoin@#[[;;2]], #[[3]]}, ""]&@
					StringSplit[path, (p:"Paths"|"Path"):>p, 2];
			heads=
				ToFileName/@
					AbsoluteCurrentValue[$FrontEndSession, path];
			file = res[[2]];
			fileNew = 
				Catch[
					Scan[
						If[StringStartsQ[file, #],
							Throw[
								StringReplace[file,
									#->
										StringReplace[
											#,
											StringSplit[#, 
												"FrontEnd"|"Fonts"|"SpellingDictionaries"|
													"Converters"|"Components", 2][[1]]->
												StringRiffle[
													{$UserBaseDirectory, "SystemFiles", ""},
													$PathnameSeparator
													]
											]
									]
								]
							]&,
						heads
						]
					];
			If[StringQ@fileNew,	
				If[autocopy,
					If[!FileExistsQ@fileNew,
						If[!DirectoryQ@DirectoryName@fileNew,
							CreateDirectory[DirectoryName@fileNew,
								CreateIntermediateDirectories->True
								]
							]
						]
					];
				fileNew,
				$Failed
				],
			$Failed
			]
		]


(* ::Subsection:: *)
(*Boxes*)


(* ::Subsubsection::Closed:: *)
(*Ref*)


Options[FEBoxRef]={
	"Start"->Automatic,
	"Offset"->1,
	"Parent"->False
	};
FEBoxRef[
	obj:
		_NotebookObject|_CellObject|_BoxObject|
		"Self"|Automatic:Automatic,
	id_,
	ops:OptionsPattern[]
	]:=
	FE`BoxReference[
		Replace[obj,{
			"Self":>FE`Evaluate[FEPrivate`Self[]],
			Automatic:>InputNotebook[]
			}],
		{
			Replace[OptionValue["Parent"],{
				True->FE`Parent,
				_->Identity
				}]@id
			},
		Replace[OptionValue["Offset"],{
			i_Integer?Positive:>
				(FE`BoxOffset->{FE`BoxChild[i]}),
			i_Integer?Negative:>
				(FE`BoxOffset->{FE`BoxParent[i]}),
			_:>
				Sequence@@{}
			}],
		Replace[OptionValue["Start"],{
			"Beginning":>
				(FE`SearchStart->"StartFromBeginning"),
			"End":>
				(FE`SearchStart->"StartFromEnd"),
			s:_String|_NotebookObject|_CellObject|_BoxObject:>
				(FE`SearchStart->s),
			_:>
				Sequence@@{}
			}]
		];


(* ::Subsubsection::Closed:: *)
(*Object*)


FEBoxObject[
	b_FE`BoxReference
	]:=
	FrontEndExecute@
		FrontEnd`BoxReferenceBoxObject[
			b
			];
FEBoxObject[
	{
		obj:
			_NotebookObject|_CellObject|_BoxObject|
				"Self"|Automatic:Automatic,
		id_,
		ops___?OptionQ
		}
	]:=
	FEBoxObject@FEBoxRef[obj,id,ops];


(* ::Subsubsection::Closed:: *)
(*Select*)


FEBoxSelect[
	b_FE`BoxReference
	]:=
	FrontEndExecute@
		FrontEnd`BoxReferenceFind[
			b
			];
FEBoxSelect[
	{
		obj:
			_NotebookObject|_CellObject|_BoxObject|
				"Self"|Automatic:Automatic,
		id_,
		ops___?OptionQ
		}
	]:=
	FEBoxSelect@FEBoxRef[obj,id,ops];


(* ::Subsubsection::Closed:: *)
(*Read*)


FEBoxRead[
	b_FE`BoxReference
	]:=
	FrontEndExecute@
		FrontEnd`BoxReferenceRead[b];
FEBoxRead[
	{
		obj:
			_NotebookObject|_CellObject|_BoxObject|
				"Self"|Automatic:Automatic,
		id_,
		ops___?OptionQ
		}
	]:=
	FEBoxRead[
		FEBoxRef[obj,id,ops]
		];


(* ::Subsubsection::Closed:: *)
(*Replace*)


FEBoxReplace[
	b_FE`BoxReference,
	arg:_String|_?BoxQ
	]:=
	FrontEndExecute@
		FrontEnd`BoxReferenceReplace[b,arg];
FEBoxReplace[b_FE`BoxReference,arg_]:=
	FEBoxReplace[b,ToBoxes@arg];
FEBoxReplace[
	{
		obj:
			_NotebookObject|_CellObject|_BoxObject|
				"Self"|Automatic:Automatic,
		id_,
		ops___?OptionQ
		},
	arg_
	]:=
	FEBoxReplace[
		FEBoxRef[obj,id,ops],
		arg];


(* ::Subsubsection::Closed:: *)
(*Edit*)


FEBoxEdit[
	b_FE`BoxReference,
	function_
	]:=
	FEBoxReplace[b,
		function@FEBoxRead[b]
		];
FEBoxEdit[
	{
		obj:
			_NotebookObject|_CellObject|_BoxObject|
				"Self"|Automatic:Automatic,
		id_,
		ops___?OptionQ
		},
	function_
	]:=
	FEBoxEdit[
		FEBoxRef[obj,id,ops],
		function
		];


(* ::Subsubsection::Closed:: *)
(*GetOptions*)


FEBoxGetOptions[
	b_FE`BoxReference
	]:=
	FrontEndExecute@
		FrontEnd`BoxReferenceGetOptions[b];
FEBoxGetOptions[
	b_FE`BoxReference,
	ops_
	]:=
	FrontEndExecute@
		FrontEnd`BoxReferenceGetOptions[b,ops];
FEBoxGetOptions[
	{
		obj:
			_NotebookObject|_CellObject|_BoxObject|
				"Self"|Automatic:Automatic,
		id_,
		ops___?OptionQ
		},
	op_
	]:=
	FEBoxGetOptions[
		FEBoxRef[obj,id,ops],
		op
		];
FEBoxGetOptions[
	{
		obj:
			_NotebookObject|_CellObject|_BoxObject|
				"Self"|Automatic:Automatic,
		id_,
		ops___?OptionQ
		}]:=
	FEBoxGetOptions[
		FEBoxRef[obj,id,ops]
		]


(* ::Subsubsection::Closed:: *)
(*SetOptions*)


FEBoxSetOptions[
	b_FE`BoxReference,
	ops_
	]:=
	FrontEndExecute@
		FrontEnd`BoxReferenceGetOptions[b,ops];
FEBoxSetOptions[
	{
		obj:
			_NotebookObject|_CellObject|_BoxObject|
				"Self"|Automatic:Automatic,
		id_,
		ops___?OptionQ
		},
	op_
	]:=
	FEBoxSetOptions[
		FEBoxRef[obj,id,ops],
		op
		];


(* ::Subsection:: *)
(*Screens*)


(* ::Subsubsection::Closed:: *)
(*Screens*)


$FETopBarHeight:=
	$FETopBarHeight=
		With[{nb=
				CreateDocument[{},
					WindowSize->{500,Scaled[1]},
					Visible->False
					]
				},
			#[[2]]-#[[1]]&@{
				Last[
					WindowSize/.AbsoluteOptions[nb,WindowSize]
					],
				SetOptions[nb,WindowFrame->"Frameless"];
				#&@(
					Last[
						WindowSize/.AbsoluteOptions[nb,WindowSize]
						])
				}
			];


$FEFrameDimensions:=
	$FEFrameDimensions=
		With[{e=
				Notebook[{
						Cell[
							BoxData[
								GraphicsBox[{},
									ImageSize->Full]
								],"Output",
							ShowCellBracket->False,
							CellMargins->0]},
					WindowSize->
					CurrentValue[WindowSize]
					]},
			FrontEndExecute[
				ExportPacket[
					Join[e,
						Notebook[WindowElements->None,WindowFrameElements->None]],
					"BoundingBox"]
				][[1,2]]-
			FrontEndExecute[ExportPacket[e,"BoundingBox"]][[1,2]]
			];


$FESideBarWidth:=
	First@$FEFrameDimensions;
$FEBottomBarHeight:=
	Last@$FEFrameDimensions;


FEWindowSize[nb_]:=
	(WindowSize/.AbsoluteOptions[nb,WindowSize])+
		Switch[CurrentValue[nb,WindowFrame],
			Automatic,
				{0,$FETopBarHeight},
			_,
				{0,0}
			]+
		{
			0,
			If[
				MemberQ[CurrentValue[nb,WindowFrameElements],"ResizeArea"]||
				MemberQ[CurrentValue[nb,WindowElements],
					"HorizontalScrollBar"|"StatusArea"|"MagnificationPopUp"],
				$FEBottomBarHeight,
				0
				]
			};


FEScreenRectangle[d:{{_,_},{_,_}}]:=
	d;
FEScreenRectangle[Full]:=
	Transpose@{{0,0},Last/@CurrentValue@ScreenRectangle};
FEScreenRectangle[{w_,h_}]:=
	With[{v=Last/@CurrentValue@ScreenRectangle},
		FEScreenRectangle[
			{
				Replace[w,
					Scaled[i_]:>i*First@v
					],
				Replace[h,
					Scaled[i_]:>i*Last@v
					]
				}
			]
		];
FEScreenRectangle[nb_NotebookObject]:=
	With[{
		rec=CurrentValue@ScreenRectangle,
		marg=
			WindowMargins/.
				AbsoluteOptions[nb,WindowMargins]
			},
		{
			{
				marg[[1,1]]+rec[[1,1]],
				rec[[1,2]]-marg[[1,2]]
				},
			{
				rec[[2,2]]-marg[[2,1]],
				rec[[2,1]]+marg[[2,2]]
				}
			}
		];
FEScreenRectangle[Automatic]:=
	FEScreenRectangle@InputNotebook[];


FEScreenShot[screen_:Automatic]:=(
	Needs["GUIKit`"];
	GUIKit`GUIScreenShot@FEScreenRectangle[screen]
	);
FECopyScreen[screen_:Automatic]:=
	CopyToClipboard@FEScreenShot[screen];


feScreenWatcher[expr_,events_,ops___]:=
	CreateDocument[expr,
		ops,
		CellInsertionPointCell->
			Cell[""],
		BlinkingCellInsertionPoint->False,
		NotebookEventActions->
			Flatten@{events},
		WindowMargins->
			{
				CurrentValue[ScreenRectangle][[1,1]],
				0
				},
		WindowSize->
			(Last/@CurrentValue[ScreenRectangle]),
		Deployed->
			True,
		WindowFrame->
			"Frameless",
		WindowOpacity->
			.5,
		Background->
			Gray
		]


(*With[{c=$Context},
FEScreenRecorder[var_:"ScreenRecorder"]:=
	With[{dynamicVar=
		Replace[var,{
			s_String:>
				With[{v=Unique[c<>s<>"$"]},
					v={};
					Dynamic[v]
					],
			s_Symbol:>
				With[{v=Unique[s]},
					v={};
					Dynamic[v]
					],
			Verbatim[Dynamic][v_]:>
				(
					v={};
					Dynamic[v]
					)
			}],
		rect=
			Create
		},
		
		
		]
	]*)


(* ::Subsection:: *)
(*Autocompletion*)


(* ::Subsubsection::Closed:: *)
(*Formats*)


$FEAutoCompletionFormats=
	Alternatives@@Join@@{
		Range[0,9],
		{
			_String?(FileExtension[#]==="trie"&),
			{
				_String|(Alternatives@@Range[0,9])|{__String},
				(("URI"|"DependsOnArgument")->_)...
				},
			{
				_String|(Alternatives@@Range[0,9])|{__String},
				(("URI"|"DependsOnArgument")->_)...,
				(_String|(Alternatives@@Range[0,9])|{__String})
				},
			{
				__String
				}
			},
		{
			"codingNoteFontCom",
			"ConvertersPath",
			"ExternalDataCharacterEncoding",
			"MenuListCellTags",
			"MenuListConvertFormatTypes",
			"MenuListDisplayAsFormatTypes",
			"MenuListFonts",
			"MenuListGlobalEvaluators",
			"MenuListHelpWindows",
			"MenuListNotebookEvaluators",
			"MenuListNotebooksMenu",
			"MenuListPackageWindows",
			"MenuListPalettesMenu",
			"MenuListPaletteWindows",
			"MenuListPlayerWindows",
			"MenuListPrintingStyleEnvironments",
			"MenuListQuitEvaluators",
			"MenuListScreenStyleEnvironments",
			"MenuListStartEvaluators",
			"MenuListStyleDefinitions",
			"MenuListStyles",
			"MenuListStylesheetWindows",
			"MenuListTextWindows",
			"MenuListWindows",
			"PrintingStyleEnvironment",
			"ScreenStyleEnvironment",
			"Style"
			}
		};


(* ::Subsubsection::Closed:: *)
(*AddAutocompletions Base*)


FEAddAutocompletions[pats:{(_String->{$FEAutoCompletionFormats..})..}]:=
	If[$Notebooks&&
		Internal`CachedSystemInformation["FrontEnd","VersionNumber"]>10.0,
		FrontEndExecute@FrontEnd`Value@
			Map[
				FEPrivate`AddSpecialArgCompletion[#]&,
				pats
				],
		$Failed
		];
FEAddAutocompletions[pat:(_String->{$FEAutoCompletionFormats..})]:=
	FEAddAutocompletions[{pat}];


(* ::Subsubsection::Closed:: *)
(*AddAutocompletions Helpers*)


$FEAutocompletionAliases=
	{
		"None"|None|Normal->0,
		"AbsoluteFileName"|AbsoluteFileName->2,
		"FileName"|File|FileName->3,
		"Color"|RGBColor|Hue|XYZColor->4,
		"Package"|Package->7,
		"Directory"|Directory->8,
		"Interpreter"|Interpreter->9,
		"Notebook"|Notebook->"MenuListNotebooksMenu",
		"StyleSheet"->"MenuListStylesheetMenu",
		"Palette"->"MenuListPalettesMenu",
		"Evaluator"|Evaluator->"MenuListGlobalEvaluators",
		"FontFamily"|FontFamily->"MenuListFonts",
		"CellTag"|CellTags->"MenuListCellTags",
		"FormatType"|FormatType->"MenuListDisplayAsFormatTypes",
		"ConvertFormatType"->"MenuListConvertFormatTypes",
		"DisplayAsFormatType"->"MenuListDisplayAsFormatTypes",
		"GlobalEvaluator"->"MenuListGlobalEvaluators",
		"HelpWindow"->"MenuListHelpWindows",
		"NotebookEvaluator"->"MenuListNotebookEvaluators",
		"PrintingStyleEnvironment"|PrintingStyleEnvironment->
			"PrintingStyleEnvironment",
		"ScreenStyleEnvironment"|ScreenStyleEnvironment->
			ScreenStyleEnvironment,
		"QuitEvaluator"->"MenuListQuitEvaluators",
		"StartEvaluator"->"MenuListStartEvaluators",
		"StyleDefinitions"|StyleDefinitions->
			"MenuListStyleDefinitions",
		"CharacterEncoding"|CharacterEncoding|
			ExternalDataCharacterEncoding->
			"ExternalDataCharacterEncoding",
		"Style"|Style->"Style",
		"Window"->"MenuListWindows"
		};


(* ::Subsubsection::Closed:: *)
(*AddAutocompletions Convenience*)


$FEAutocompletionTable={
	f:$FEAutoCompletionFormats:>f,
	Sequence@@$FEAutocompletionAliases,
	s_String:>{s}
	};


FEAddAutocompletions[o:{__Rule}]/;(!TrueQ@$recursionProtect):=
	Block[{$recursionProtect=True},
		Replace[
			FEAddAutocompletions@
				Replace[o,
					(s_->v_):>
						(Replace[s,_Symbol:>SymbolName[s]]->
							Replace[
								Flatten[{v},1],
								$AutocompletionTable,
								1
								]),
					1
					],
			_FEAddAutocompletions->$Failed
			]
		];
FEAddAutocompletions[s:Except[_List],v_]:=
	FEAddAutocompletions[{s->v}];
FEAddAutocompletions[l_,v_]:=
	FEAddAutocompletions@
		Flatten@{
			Quiet@
				Check[
					Thread[l->v],
					Map[l->#&,v]
					]
			};


(*FEAddAutocompletions[FEAddAutocompletions,
	{None,
		Join[
			Replace[Keys[$FEAutocompletionAliases],
				Verbatim[Alternatives][s_,___]:>s,
				1
				],
			{FileName,AbsoluteFileName}/.$FEAutocompletionAliases
			]
		}
	]*)


(* ::Subsection:: *)
(*Notebooks*)


(* ::Subsubsection::Closed:: *)
(*FEAttachCell*)


FEAttachCell//Clear;
FEAttachCell[
	parent:(_CellObject|_NotebookObject|_BoxObject|Automatic):Automatic,
	expr_,
	radialAway:
		_Offset|_Integer|_Scaled|
		{_Integer|_Scaled,_Integer|_Scaled}|
		Automatic:
		Automatic,
	alignment:
		{
			Center|Left|Right,
			Center|Bottom|Top
			}|
		Center|Left|Right|Bottom|Top|
		Automatic:Automatic,
	anchor:
		{
			Center|Left|Right|_Scaled|_Integer|_Real,
			Center|Bottom|Top|_Scaled|_Integer|_Real
			}|
		Center|Left|Right|Bottom|Top|
		Automatic:Automatic,
	closingActions:{
		("ParentChanged"|"EvaluatorQuit"|
			"OutsideMouseClick"|"SelectionDeparture"|"MouseExit")...}:
		{"ParentChanged","EvaluatorQuit"}
		]:=
		FrontEndExecute@
			FrontEnd`AttachCell[
				Replace[parent,Automatic:>EvaluationCell[]],
				Replace[expr,
					Except[_Cell|_TextCell|_ExpressionCell]:>
						If[MatchQ[parent,_NotebookObject],
							Cell[BoxData@ToBoxes@expr,
								"DockedCell",
								Background->GrayLevel[.95],
								TextAlignment->Center,
								CellSize->
									Replace[
										Replace[alignment,
											Automatic:>
												Replace[anchor,Automatic->Top]],{
										Bottom|Top->{
											Dynamic[First@CurrentValue[parent,WindowSize]],
											Automatic
											},
										Left|Right->{
											Automatic,
											Dynamic[Last@CurrentValue[parent,WindowSize]]
											},
										_->{Scaled[1],Automatic}
										}],
								CellFrame->
									Replace[
										Replace[alignment,
											Automatic:>
												Replace[anchor,Automatic->Top]],{
										Bottom->{{0,0},{0,1}},
										Top->{{0,0},{1,0}},
										Left->{{0,1},{0,0}},
										Right->{{1,0},{0,0}},
										_->{{1,1},{1,1}}
										}]
												
								],
							Cell[BoxData@ToBoxes@expr]
							]
					],
				{
					Replace[radialAway,
						{a_,b_}:>Offset[{a,b},0]
						],
					Replace[alignment,
						Automatic:>
							If[MatchQ[parent,_NotebookObject],
								Replace[anchor,{
									Automatic->
										{Center,Top},
									tb:(Top|Bottom):>
										{Center,tb},
									lr:(Left|Right):>
										{lr,Center}
									}],
								{Left,Bottom}
								]
						]},
				Replace[anchor,
					Automatic:>
						If[MatchQ[parent,_NotebookObject],
							Replace[alignment,{
								Automatic->
									{Center,Top},
								tb:(Top|Bottom):>
									{Center,tb},
								lr:(Left|Right):>
									{lr,Center}
									}],
							{Left,Top}
							]
					],
				"ClosingActions"->
					If[MatchQ[parent,_NotebookObject],
						DeleteDuplicates[closingActions/."ParentChanged"->"OutsideMouseClick"],
						closingActions
						]
				];


(* ::Subsubsection::Closed:: *)
(*FENotebooks*)


FENotebooks[f_String?FileExistsQ]:=
	List@SelectFirst[FrontEndExecute@FrontEnd`ObjectChildren[$FrontEnd],
Quiet@NotebookFileName@#===f&
		];
FENotebooks[Optional["*","*"]]:=
	FrontEndExecute@FrontEnd`ObjectChildren[$FrontEnd];
FENotebooks[pat:Except["*"|_String?FileExistsQ]]:=
	Select[FrontEndExecute@FrontEnd`ObjectChildren[$FrontEnd],
		Replace[Quiet@NotebookFileName@#,{
				s_String:>
					StringMatchQ[s,pat],
				_->False
				}
			]||
		Replace[Quiet@NotebookFileName@#,{
				s_String:>
					FileBaseName@StringMatchQ[s,pat],
				_->False
				}
			]||
		StringMatchQ[
			WindowTitle/.AbsoluteOptions[#,WindowTitle],
			pat
			]&
		]


(* ::Subsubsection::Closed:: *)
(*SelectCells*)


FESelectCells[
	nbObj:_NotebookObject|Automatic:Automatic,
	test_:(True&)
	]:=
	Module[{
		nb=Replace[nbObj,Automatic:>InputNotebook[]],
		cells
		},
		cells=
			Replace[test,{
				s:_String|{__String}:>
					Cells[nb,CellStyle->s],
				r_Rule:>
					Cells[nb,r],
				_:>Select[Cells[nb],test]
				}];
		If[Quiet[NotebookFileName[nb]]===$Failed,
			SetSelectedNotebook[nb]
			];
		Function[
			SelectionMove[#,All,Cell,AutoScroll->False];
			FrontEndExecute@
				FrontEnd`SelectionAddCellTags[
					nb,
					"---ToCopy---"
					];
			]/@cells;
		If[Quiet[NotebookFileName[nb]]===$Failed,
			NotebookLocate["---ToCopy---",AutoScroll->False],
			NotebookLocate[
				{NotebookFileName[nb],"---ToCopy---"},
				AutoScroll->False]
			];
		FrontEndExecute@
			FrontEnd`SelectionRemoveCellTags[
				nb,
				"---ToCopy---"
				];
		]


(* ::Subsection:: *)
(*Symbol Coloring*)


(* ::Subsubsection::Closed:: *)
(*FEHiddenBlock*)


FEHiddenBlock[expr_]:=
(
		Internal`SymbolList[False];
		(Internal`SymbolList[True];#)&@expr
		);
FEHiddenBlock~SetAttributes~HoldAllComplete;


(* ::Subsubsection::Closed:: *)
(*FEUnhideSymbols*)


FEUnhideSymbols[syms__Symbol,
	cpath:{__String}|Automatic:Automatic,
	mode:"Update"|"Set":"Update"
	]:=
	With[{stuff=
		Map[
			Function[Null,
				{Context@#,SymbolName@Unevaluated@#},
				HoldAllComplete],
			HoldComplete[syms]
			]//Apply[List]
		},
		KeyValueMap[
			FrontEndExecute@
			If[mode==="Update",
				FrontEnd`UpdateKernelSymbolContexts,
				FrontEnd`SetKernelSymbolContexts
				][
				#,
				Replace[cpath,Automatic->$ContextPath],
				{{#,{},{},#2,{}}}
				]&,
			GroupBy[stuff,First->Last]
			];
		];
FEUnhideSymbols[names_String,mode:"Update"|"Set":"Update"]:=
	Replace[
		Thread[ToExpression[Names@names,StandardForm,Hold],Hold],
		Hold[{s__}]:>FEUnhideSymbols[s,mode]
		];
FEUnhideSymbols~SetAttributes~HoldAllComplete;


(* ::Subsubsection::Closed:: *)
(*FERehideSymbols*)


FERehideSymbols[syms__Symbol,
	cpath:{__String}|Automatic:Automatic,
	mode:"Update"|"Set":"Update"]:=
	With[{stuff=
		Map[
			Function[Null,
				{Context@#,SymbolName@Unevaluated@#},
				HoldAllComplete],
			HoldComplete[syms]
			]//Apply[List]
		},
		KeyValueMap[
			FrontEndExecute@
			If[mode==="Update",
				FrontEnd`UpdateKernelSymbolContexts,
				FrontEnd`SetKernelSymbolContexts
				][
				#,
				Replace[cpath,
					Automatic->$ContextPath
					],
				{{#,{},#2,{},{}}}
				]&,
			GroupBy[stuff,First->Last]
			];
		];
FERehideSymbols[names_String,mode:"Update"|"Set":"Update"]:=
	Replace[
		Thread[ToExpression[Names@names,StandardForm,Hold],Hold],
		Hold[{s__}]:>FERehideSymbols[s,mode]
		];
FERehideSymbols~SetAttributes~HoldAllComplete;


(* ::Subsubsection::Closed:: *)
(*FESetSymbolColoring*)


FESetSymbolColoring[
	{syms__},
	cont:_String|Automatic:Automatic,
	contPath:{__String}|Automatic:Automatic,
	which:
	"Undefined"|"Removed"|"Defined"|"Cleared"|
	1|2|3|4|{(1|2|3|4|"Undefined"|"Removed"|"Defined"|"Cleared")..}
	]:=
	With[{
			stuff=
			Map[
				Function[Null,
					If[StringQ@Unevaluated[#],
						Replace[
							StringSplit[#,"`",2],
							{{c_,s_}:>{c<>"`",s},{s_}:>{$Context,s}}
							],
						{Context@#,SymbolName@Unevaluated@#}
						],
					HoldAllComplete
					],
				HoldComplete[syms]
				]//Apply[List],
			whi=
			Replace[Flatten@{which},
				{
					"Undefined"->1,
					"Removed"->2,
					"Defined"->3,
					"Cleared"->4
					},
				1
				]
			},
		FrontEndExecute@
		FrontEnd`UpdateKernelSymbolContexts[
			Replace[cont,Automatic:>$Context],
			Replace[contPath,Automatic:>$ContextPath],
			KeyValueMap[
				With[{symlist=#2},
					Prepend[Replace[cont,Automatic:>#]]@
					Fold[
						ReplacePart[#,#2->symlist]&,
						ConstantArray[{},4],
						whi
						]
					]&,
				GroupBy[stuff,First->Last]
				]
			]
		];
FESetSymbolColoring[s_,a___]:=
	FESetSymbolColoring[{s},a];
FESetSymbolColoring~SetAttributes~HoldAllComplete;


(* ::Subsection:: *)
(*Autocompletions*)


(* ::Subsubsection::Closed:: *)
(*FindFileOnPath*)


FEAddAutocompletions[
	"FEFindFileOnPath",
	{
		None,
		StringTrim[
			StringTrim[
				DeleteDuplicates@Values@$FEPathMap,
				"PrivatePaths"|"Path"|"NotebookSecurityOptions"
				],
			"s"
			]}
	];


(* ::Subsection::Closed:: *)
(*End Private*)


End[];


(* ::Section:: *)
(*End Package*)


EndPackage[]
