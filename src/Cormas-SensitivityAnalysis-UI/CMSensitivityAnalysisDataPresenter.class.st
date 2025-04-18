Class {
	#name : 'CMSensitivityAnalysisDataPresenter',
	#superclass : 'SpPresenter',
	#instVars : [
		'translator',
		'sensitivityAnalysis',
		'progressBar',
		'runButton',
		'dataNotebook',
		'simulationsTable',
		'dataTable',
		'simulationsCountLabel'
	],
	#category : 'Cormas-SensitivityAnalysis-UI',
	#package : 'Cormas-SensitivityAnalysis-UI'
}

{ #category : 'examples' }
CMSensitivityAnalysisDataPresenter class >> example [
	<example>
	
	| sensitivityAnalysis translator |
	
	sensitivityAnalysis := (CMSensitivityAnalysis for: CMMockModel)
		activeInitSelector: #initFixed;
		activeControlSelector: #step:;
		yourself.
	
	CMMockModel parameters do: [ :parameter |
		1 to: 5 do: [ :value | 
			sensitivityAnalysis addSimulationForParameter: parameter value: value ] ].
	
	translator := CMEnglishTranslator new.
	
	^ (self forAnalysis: sensitivityAnalysis translator: translator) open
]

{ #category : 'as yet unclassified' }
CMSensitivityAnalysisDataPresenter class >> forAnalysis: aSensitivityAnalysis translator: aTranslator [

	^ self on: { aSensitivityAnalysis . aTranslator }
]

{ #category : 'adding' }
CMSensitivityAnalysisDataPresenter >> addChartsPage [
	
	| parameters measurementNames |
	
	parameters := (sensitivityAnalysis simulations
		flatCollect: [ :each | each initialParameterValues keys ]) asSet asOrderedCollection.
		
	measurementNames := sensitivityAnalysis data first keys allButFirst: 4.

	dataNotebook addPage: (SpNotebookPage
		title: 'Charts'
		icon: CMIcons chartIcon
		provider: [ (self instantiate: CMSensitivityAnalysisChartsPresenter)
			data: sensitivityAnalysis data;
			numberOfRepetitions: sensitivityAnalysis numberOfRepetitions;
			measurementNames: measurementNames;
			parameters: parameters;
			drawCharts;
			yourself ]).
]

{ #category : 'initialization' }
CMSensitivityAnalysisDataPresenter >> connectPresenters [

	runButton action: [ self runSimulations ]
]

{ #category : 'layout' }
CMSensitivityAnalysisDataPresenter >> defaultLayout [

	^ SpPanedLayout newTopToBottom
		add: (SpBoxLayout newTopToBottom
			spacing: 10;
			add: (SpBoxLayout newTopToBottom
				spacing: 2;
				add: 'Simulations' height: self class labelHeight;
				add: simulationsTable;
				yourself);
			add: (SpBoxLayout newLeftToRight
				spacing: 20;
				add: runButton expand: false;
				add: (SpBoxLayout newTopToBottom
					add: 'Progress:';
					add: simulationsCountLabel expand: false;
					yourself) expand: false;
				add: progressBar;
				yourself) height: self class labelHeight * 2 + 3;
			yourself);
		add: dataNotebook;
		yourself
]

{ #category : 'initialization' }
CMSensitivityAnalysisDataPresenter >> initializePresenters [

	runButton := self newButton
		icon: CMIcons runIcon;
		label: 'Run all';
		yourself.
		
	progressBar := self newProgressBar.
	
	simulationsTable := self newTable
		contextMenu: (SpMenuPresenter new 
			addItem: [ :item | item 
				name: 'Open simulation'; 
				icon: CMIcons runIcon;
				action: [
					CMSimulationRunnerPresenter
						openForSimulation: (
							simulationsTable selectedItem
								randomSeed: sensitivityAnalysis randomSeed;
								initializeSimulation;
								yourself)
						withTranslator: translator ] ];
			yourself);
		items: sensitivityAnalysis simulations;
		addColumn: (SpStringTableColumn
			title: 'Parameter class'
			evaluated: [ :simulation | simulation initialParameterValues keys anyOne receiver name ]);
		addColumn: (SpStringTableColumn
			title: 'Parameter name'
			evaluated: [ :simulation | simulation initialParameterValues keys anyOne name ]);
		addColumn: (SpStringTableColumn
			title: 'Parameter value'
			evaluated: [ :simulation | simulation initialParameterValues values anyOne ]);
		addColumn: (SpStringTableColumn
			title: 'Progress'
			evaluated: [ :simulation | self progressStringFrom: 0 ] )
		yourself.
	
	dataNotebook := self newNotebook.
	
	dataNotebook addPage: (SpNotebookPage
		title: 'Data'
		icon: (self iconNamed: #database)
		provider: [ dataTable := self instantiate: CMDataPresenter on: translator ]).
		
	simulationsCountLabel := self newLabel.
	self updateSimulationsCountLabel.
]

{ #category : 'initialization' }
CMSensitivityAnalysisDataPresenter >> initializeWindow: aWindowPresenter [

	super initializeWindow: aWindowPresenter.
	
	aWindowPresenter 
		title: translator tSensitivityAnalysis;
		initialExtent: 800@650.
]

{ #category : 'as yet unclassified' }
CMSensitivityAnalysisDataPresenter >> progressStringFrom: aNumber [
	"Expects value between 0 and 1"
	
	| totalNumberOfTicks numberOfCompletedTicks numberOfUncompletedTicks |
	
	totalNumberOfTicks := 20.
	numberOfCompletedTicks := (aNumber * totalNumberOfTicks) rounded.
	numberOfUncompletedTicks := totalNumberOfTicks - numberOfCompletedTicks.
	
	^ String streamContents: [ :stream |
		stream nextPut: $[.
		numberOfCompletedTicks timesRepeat: [ stream nextPut: $# ].
		numberOfUncompletedTicks timesRepeat: [ stream nextPut: $_ ].
		stream
			nextPutAll: '] ';
			nextPutAll: (aNumber * 100) rounded asString;
			nextPut: $% ].
]

{ #category : 'as yet unclassified' }
CMSensitivityAnalysisDataPresenter >> runSimulations [

	sensitivityAnalysis runAfterEachRepetitionDo: [
		self updateSimulationsCountLabel.
		self updateProgressBar].
	
	self showData.
	self addChartsPage.
]

{ #category : 'accessing - model' }
CMSensitivityAnalysisDataPresenter >> setModelBeforeInitialization: aCollection [

	sensitivityAnalysis := aCollection first.
	translator := aCollection second
]

{ #category : 'as yet unclassified' }
CMSensitivityAnalysisDataPresenter >> showData [

	| data |
	data := sensitivityAnalysis data.
	
	data ifEmpty: [ ^ self ].
	
	dataTable columnNames: data anyOne keys.
	dataTable showData: sensitivityAnalysis data.
]

{ #category : 'as yet unclassified' }
CMSensitivityAnalysisDataPresenter >> updateProgressBar [

	progressBar fixedAt: (sensitivityAnalysis data size / sensitivityAnalysis totalNumberOfRuns) 
]

{ #category : 'as yet unclassified' }
CMSensitivityAnalysisDataPresenter >> updateSimulationsCountLabel [

	simulationsCountLabel label: (String streamContents: [ :stream |
		stream
			<< 'Finished '
			<< (sensitivityAnalysis data size // sensitivityAnalysis numberOfRepetitions) asString
			<< ' out of '
			<< sensitivityAnalysis simulations size asString
			<< ' simulations' ])
]
