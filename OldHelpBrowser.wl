(* ::Package:: *)

(* ::Section:: *)
(*OldHelpBrowser*)


BeginPackage["OldHelpBrowser`"];


(*Package Declarations*)
OpenHelpBrowser::usage="
OpenHelpBrowser[] opens an old-style help browser
OpenHelpBrowser[path] opens an old-style help browser intialized with path
";


(* ::Subsubsection::Closed:: *)
(*Private Declarations*)


AppendTo[$ContextPath,$Context<>"Package`"];


Begin["`Package`"];


(*Package Declarations*)
loadDocumentationData::usage="loadDocumentationData[]";
loadDocumentationMetadata::usage="loadDocumentationMetadata[]";
ensureLoadedDocumentationMetadata::usage="ensureLoadedDocumentationMetadata[]";
preLoadDocumentationMetadata::usage="preLoadDocumentationMetadata[]";
loadCachedDocumentationData::usage="loadCachedDocumentationData[]";
cacheDocumentationData::usage="cacheDocumentationData[]";
clearCachedDocumentationData::usage="clearCachedDocumentationData[]";
$helpSearcherDocData::usage="The core doc data Association";
$helpSearcherDocMetadataDS::usage="$helpSearcherDocMetadataDS";
helpBrowserCoreDS::usage="helpBrowserCoreDS";
helpBrowserDSButton::usage="helpBrowserDSButton[entry, onClick]";
helpBrowserDS::usage="helpBrowserDS[formatFunction, onClick]";
helpSearcherDSNameSearch::usage="helpSearcherDSNameSearch[name, type]";
helpBrowserNameSearch::usage="helpBrowserNameSearch[browser, name, type]";
helpBrowserSearch::usage="helpBrowserSearch[browser, name, type]";
helpBrowserDockedCell::usage="helpBrowserDockedCell[path]";
helpBrowserNotebook::usage="helpBrowserNotebook[path]";


End[];


Begin["`Private`"];


(* ::Subsection:: *)
(*Implementation*)


(*Package Implementation*)


(* ::Subsubsection::Closed:: *)
(*Load Data*)


loadDocumentationData[] :=
 $helpSearcherDocData =
  Append[#,
     "Pages" ->
      Apply[Join]@
       Map[FileNames["*.nb", Last[#], \[Infinity]] &, #["Directories"]]
     ] &@
   <|
    "Directories" ->
     Join[
      DeleteDuplicatesBy[#[[1]]["Name"] &]@
       Select[DirectoryQ@*Last]@
        Map[
         # -> FileNameJoin[{#["Location"], "Documentation"}] &,
         PacletManager`PacletFind["*"]
         ],
       {"System"->FileNameJoin[{$InstallationDirectory, "Documentation"}]}
      ]
    |>


loadDocumentationMetadata[] :=
 (
  If[! AssociationQ@$helpSearcherDocData, loadDocumentationData[]];
  $helpSearcherDocData["Metadata"] =
   Association@
    Map[
     # :>
       Set[
        $helpSearcherDocData["Metadata", #],
        Append[
         Fold[Association@Lookup[#, #2, {}] &, 
          Options[Get[#]], {TaggingRules, "Metadata"}],
         "File" -> #
         ]
        ] &,
     $helpSearcherDocData["Pages"]
     ]
  )


ensureLoadedDocumentationMetadata[] :=
 
 If[! AssociationQ@$helpSearcherDocData || ! 
    KeyMemberQ[$helpSearcherDocData, "Metadata"],
  loadDocumentationMetadata[]
  ]


preLoadDocumentationMetadata[] :=
(ensureLoadedDocumentationMetadata[]; 
  Scan[Identity, $helpSearcherDocData["Metadata"]])


(* ::Subsubsection::Closed:: *)
(*Cache Data*)


loadCachedDocumentationData::corrupt="Cache has been corrupted. It will be ignored.";
loadCachedDocumentationData[] :=
  Catch[
   $helpSearcherDocData = 
     Replace[Get[LocalObject["docsDataCache"]],
      a_Association?(
       !AssociationQ[#["Metadata"]]||Length[#["Metadata"]]===0
       &):>
       (Message[loadCachedDocumentationData::corrupt];Throw@$Failed)
      ]
   ];
cacheDocumentationData[] :=
  Put[$helpSearcherDocData, LocalObject["docsDataCache"]];
clearCachedDocumentationData[] :=
  Quiet@DeleteFile@LocalObject["docsDataCache"];


(* ::Subsubsection:: *)
(*Docs Metadata Dataset*)


$helpSearcherDocMetadataDS :=
  $helpSearcherDocMetadataDS =
   (
    preLoadDocumentationMetadata[];
    Dataset@
     Select[Values@$helpSearcherDocData["Metadata"], KeyMemberQ["uri"]]
    );


(* ::Subsubsection::Closed:: *)
(*Help Browser Tree*)


helpBrowserCoreDS :=
  helpBrowserCoreDS =
   GroupBy[
    $helpSearcherDocMetadataDS,
    Key["type"] -> KeyDrop["type"],
    GroupBy[Key["context"] -> KeyDrop["context"]]
    ];


helpBrowserDSButton[entry_, onClick_] :=
  Column[{
    Button[#,
       onClick["paclet:" <> #2, #],
       BaseStyle -> "Hyperlink",
       Appearance -> None,
       Method -> "Queued"
       ] & @@ Lookup[entry, {"title", "uri"}],
    If[StringQ@#,
       Pane[#, {400, UpTo[250]}, ImageSizeAction -> "Scrollable"],
       #
       ] &@Lookup[entry, "summary", Nothing]
    }];
helpBrowserDS[
  formatFunction_: helpBrowserDSButton,
  onClick_: Documentation`HelpLookup
  ] :=
 Map[
   Association@*
    Map[
     Lookup[#, "title"] ->
       formatFunction[#, onClick]
      &
     ]
   ] /@ helpBrowserCoreDS


(* ::Subsubsection::Closed:: *)
(*Constants*)


$helpBrowserTaggingRulesPath={TaggingRules,"OldHelpBrowser","Path"};


(* ::Subsubsection::Closed:: *)
(*Search*)


helpSearcherDSNameSearch[name_, type_:"Symbol"]:=
 SortBy[
  Normal@Select[$helpSearcherDocMetadataDS,
   #type===type&&StringContainsQ[#title, name]&
   ],
  StringLength[#["title"]]&
  ]


helpBrowserNameSearch[browser_, name_, type_:"Symbol"]:=
  With[{
    result=Replace[helpSearcherDSNameSearch[name,type], {a_,___}:>a],
    path=$helpBrowserTaggingRulesPath
    },
    If[AssociationQ@result,
      CurrentValue[browser, path] =
        Lookup[result, {"type", "context", "title"}]
      ]
    ]


(* ::Subsubsection::Closed:: *)
(*PacletLookup*)


helpBrowserPacletLookup[browser_ ,pacletURI_]:=
 CurrentValue[browser, $helpBrowserTaggingRulesPath]=
  With[{baseFile=Documentation`ResolveLink[pacletURI]},
   Lookup[
    Lookup[$helpSearcherDocData["Metadata"],baseFile,
     <|"type"->Nothing,"context"->Nothing,"title"->Nothing|>
     ],
    {"type","context","title"}
    ]
   ]


(* ::Subsubsection::Closed:: *)
(*HelpBrowserSearch*)


helpBrowserSearch[browser_, name_, type_:"Symbol"]:=
 With[{pl=Documentation`ResolveLink[name]},
  Print@pl;
  If[pl=!=Null&&!
   StringStartsQ[pl,
    FileNameJoin@{PacletManager`$UserBasePacletsDirectory,"Temporary"}
    ],
   helpBrowserPacletLookup[browser,name],
   helpBrowserNameSearch[browser,name,type]
   ]
  ]


(* ::Subsubsection::Closed:: *)
(*Styles*)


$helpBrowserStyleDefinitions=
Notebook[{
 Cell[
  StyleData[
   StyleDefinitions->
    FrontEnd`FileName[{"Wolfram"}, "Reference.nb",
     CharacterEncoding -> "UTF-8"
     ]
   ]
  ],
 Cell[StyleData["Link"],
  ButtonBoxOptions->{
   ButtonFunction:>
    Function[
     KernelExecute[helpBrowserPacletLookup[EvaluationNotebook[],#]]
     ],
   Evaluator->"Local"
   }
  ]
 }];


(* ::Subsubsection:: *)
(*Docked Cell*)


Off[General::shdw];
System`WholeCellGroupOpener;
On[General::shdw];


helpBrowserDockedCell[path : _List : {}] :=
  DynamicModule[
   {
    panePathCached,
    paneCorePath,
    searchString,
    panePicker,
    panePickerHeight = 150,
    panePickerHeightBase,
    coreDS,
    setNB,
    showBrowser = True,
    currentLoadedPath,
    listPickerLineHeight = 20,
    resizeDragBase,
    inDrag=False
    },
   With[{p=$helpBrowserTaggingRulesPath},
    CurrentValue[EvaluationNotebook[], p] = path
    ];
   coreDS = 
    Normal@helpBrowserDS["paclet:" <> Lookup[#, {"uri"}, ""] &, 
      Null];
   panePicker =
    Function@
     With[{
       choices = #, idx = #2,
       pp = panePathCached
       },
      ListPicker[
       Dynamic[
        If[Length@pp >= idx, pp[[{idx}]]],
        Function@
         With[{p=$helpBrowserTaggingRulesPath},
          Set[
           CurrentValue[EvaluationNotebook[], p ],
           ReplacePart[
            If[Length@pp >= idx,
             Take[pp, idx],
             PadRight[pp, idx, ""]
             ], 
            idx -> First@#]
           ]
          ]
        ],
       Map[#->Pane[#,{Full,listPickerLineHeight}]&,choices],
       With[{wlpp=If[Length@pp===3, 2, Length@pp]},
        ImageSize -> {
         Scaled[1 / (wlpp + 1) ], 
         Full
         }
        ],
       Background -> {{GrayLevel[.98], White}},
       Appearance->"Frameless",
       If[Length@pp >= idx&&MemberQ[choices, pp[[idx]]],
        ScrollPosition->{
         0, 
         With[{p1=FirstPosition[choices, pp[[idx]] ][[1]]},
          If[p1>6,(1+p1)*listPickerLineHeight-100,0]
          ]
         },
        Sequence@@{}
        ],
       Spacings->0
       ]
      ];
   setNB =
    Function[
     If[currentLoadedPath =!= panePathCached,
      CheckAll[
       FrontEndExecute@
        FrontEnd`NotebookSuspendScreenUpdates[EvaluationNotebook[]];
       SelectionMove[EvaluationNotebook[], All, Notebook];
       SetOptions[NotebookSelection[EvaluationNotebook[]], 
        Deletable -> True];
       NotebookDelete[EvaluationNotebook[]];
       With[{
         nb =
          DeleteCases[
            WindowSize | WindowMargins | DockedCells | 
              StyleDefinitions -> _]@
           Replace[Documentation`ResolveLink[#], {
             f_String?FileExistsQ :> Import[f],
             _ -> Notebook[{}]
             }]
         },
        Replace[
         Fold[
          Lookup[#,#2,<||>]&,
          Options[nb],
          {TaggingRules,"Metadata","uri"}
          ],
          s_String:>Set[searchString,s]
          ];
        NotebookWrite[
         EvaluationNotebook[],
         First@nb
         ];
        SetOptions[EvaluationNotebook[],
         Join[
          {
           StyleDefinitions -> $helpBrowserStyleDefinitions,
           TaggingRules -> 
             Join[
              Lookup[Options[nb],TaggingRules],
              CurrentValue[EvaluationNotebook[], TaggingRules]
              ]
           },
          List @@ DeleteCases[TaggingRules->_]@Rest@nb
          ]
         ]
        ];
       SelectionMove[EvaluationNotebook[], Before, Notebook];
       FrontEndExecute@
        FrontEnd`NotebookResumeScreenUpdates[EvaluationNotebook[]],
       FrontEndExecute@
        FrontEnd`NotebookResumeScreenUpdates[EvaluationNotebook[]]
       ];
      currentLoadedPath = panePathCached
      ];
     Nothing
     ];
   Dynamic@
    If[showBrowser,
     With[{pp=
      Replace[
       CurrentValue[EvaluationNotebook[], 
        $helpBrowserTaggingRulesPath
        ],
       Except[_List]->path
       ]
      },
     panePathCached = pp;
     Grid[{
       List@Item[#,Alignment->Right]&@Button[
        Row[
         {
          "",
          ToExpression@FrontEndResource["FEBitmaps","SquareMinusIconMedium"],
          "Hide Browser"
          },
         Spacer[2]
         ],
        showBrowser = False,
        Appearance -> None,
        BaseStyle -> "Message"
        ],
       List@Item[#,Alignment->Scaled[.5]]&@
       Row[{
        EventHandler[
         InputField[Dynamic[searchString],String, FieldSize->35],
         "ReturnKeyDown":>helpBrowserSearch[EvaluationNotebook[], searchString]
         ],
        Button["",
         helpBrowserSearch[EvaluationNotebook[], searchString],
         Appearance->
          Function[{
            "Default"->#,
            "Hover"->
              Image[Darker[#,.5],
               "Byte",
               "ColorSpace"->"RGB",
               Interleaving->True],
             "Pressed"->
              Image[Lighter[#,.5],
               "Byte",
               "ColorSpace"->"RGB",
               Interleaving->True]
             }]@ToExpression@FrontEndResource["FEBitmaps","SearchIcon"]
           ]
        },
        Spacer[8]
        ],
        With[{paneCore=
         Framed[
          Row@
           Prepend[
            MapIndexed[
             Replace[
               coreDS @@ Take[pp, #2[[1]]], {
                a_Association :> 
                 panePicker[
                  SortBy[a // Keys // Sort, #=!="System`"&], 
                  #2[[1]
                  ] + 1],
                e_ :> setNB[e]
                }] &,
             pp
             ],
            panePicker[Keys[coreDS], 1]
            ],
          ImageSize->Full,
          Background->White,
          FrameStyle->Gray,
          FrameMargins->None
          ]},
         List@
           Column[{
            Dynamic[
             Pane[
              paneCore,
              ImageSize->{Full, panePickerHeight},
              AppearanceElements -> None
              ],
             TrackedSymbols:>{panePickerHeight}
             ],
           EventHandler[
           MouseAppearance[#,"FrameTBResize"]&@
             Graphics[
              {},
              Background->GrayLevel[.7],
              ImageSize->{Full,2},
              AspectRatio->Full,
              ImagePadding->None,
              Method->{"ShrinkWrap"->True},
              ImageMargins->0
              ],{
            "MouseDown":>
              (
               If[!NumericQ@resizeDragBase,
                Replace[MousePosition["ScreenAbsolute"],
                 {_,y_}:>Set[resizeDragBase,y]
                 ]
                ];
               If[!NumericQ@panePickerHeightBase,
                panePickerHeightBase=panePickerHeight
                ]
               ),
            "MouseUp":>
             Clear[resizeDragBase,panePickerHeightBase],
            "MouseDragged":>
             (
              Replace[MousePosition["ScreenAbsolute"],
               {_,m_}:>
                If[!NumericQ@resizeDragBase,
                 Set[resizeDragBase,m];
                 panePickerHeightBase=panePickerHeight,
                 With[{
                  new = panePickerHeightBase +  m - resizeDragBase,
                  old = panePickerHeight
                  },
                  panePickerHeight = new
                  ]
                 ]
               ]
              ),
            PassEventsDown->True
            }]
           },
           Spacings->0
           ]
        ]
       }]
      ],
     Button[
      Column[{Row[{
       "",
       ToExpression@FrontEndResource["FEBitmaps","SquarePlusIconMedium"],
       "Show Browser"
       },
       Spacer[2]
       ],
       Spacer[5]
       },
       Spacings->0
       ],
      showBrowser = True,
      Appearance -> None,
      BaseStyle -> "Message"
      ]
     ]
   ];


helpBrowserNotebook[path : _List : {}] :=
  Notebook[{},
   DockedCells ->
    Cell[BoxData@ToBoxes@helpBrowserDockedCell[path],
     CellFrame -> {{0, 0}, {1, 0}},
     CellMargins -> None,
     CellFrameMargins -> {{0,0},{-6,0}},
     TextAlignment->Right
     ],
   System`ClosingSaveDialog -> False,
   Saveable -> False,
   WindowTitle -> "Help Browser"
   ];


(* ::Subsubsection:: *)
(*OpenHelpBrowser*)


OpenHelpBrowser[path : _List : {}] :=
 
 If[MatchQ[$helpBrowser, _NotebookObject?(NotebookRead[#] =!= $Failed \
&)],
  SetOptions[$helpBrowser, {
    WindowFloating -> True,
    Visible -> True
    }];
  SetOptions[$helpBrowser, WindowFloating -> False],
  Quiet@
   Check[
    loadCachedDocumentationData[],
    preLoadDocumentationMetadata[];
    cacheDocumentationData[]
    ];
  $helpBrowser = CreateDocument@helpBrowserNotebook[]
  ]


(* ::Subsection:: *)
(*End*)


End[];


EndPackage[];
