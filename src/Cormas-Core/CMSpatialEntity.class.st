"
I'm representing a spatial entity. Spatial entities define a topological support for simulations. They hold natural resources and arbitrate their allocation according to pre-defined protocols based on a metaphor of physical harvest.


LEGACY behind this line. To be removed.
---------------------------------------------------------------------------------------------------------------------

newBoss: attributList 
	""Create Entity with only  #id value.
	To add some other values of attributes, newBoss: must be redefine.
Ex: With attributList = OrderedCollection (1  3), this method will create a new instance of ObjectLocation with id= 1 and patchID = 3. Then it will move the entity on the third cell.
To redefine newBoss: it could be as following:
newBoss: attributList 
	| ag |
	ag := super newBoss: (attributList copyFrom: 1 to: 2).
	2 timesRepeat: [attributList removeFirst].
	attributList with: #(#name: #cashbox:)
		do: [:array1Element :array2Element | ag perform: array2Element with: array1Element].

the  attributList = OrderedCollection (1  3 'LandOwner-1' 2000).
The attributs names must have been specified in the #representBinaryOn: instance method.
Ex:
representBinaryOn: bos 
	| msg |
	msg := super representBinaryOn: bos.
	msg arguments first add: self name; add: self cashbox.
	^msg

Then, the first 3 values of attributList must be for the #id, #dead and patchID of the agent.
The others are for the name and the cashbox values.""

	| ag |
	ag := self new.
	attributList do: [: assoc | 
ag update: (assoc key asString) to:  assoc value
""ag perform: (assoc key, ':') asSymbol with: assoc value""].
	^ag

"
Class {
	#name : 'CMSpatialEntity',
	#superclass : 'CMEntity',
	#instVars : [
		'spaceModel',
		'destroyed',
		'theOccupants',
		'neighbourhoodWithNils',
		'aggregates'
	],
	#category : 'Cormas-Core-Entities',
	#package : 'Cormas-Core',
	#tag : 'Entities'
}

{ #category : 'utilities' }
CMSpatialEntity class >> connectedCellsAmong: aListOfCells [
	"From aListOfCells, returns collections of cells that are connected (= each subcollection contains connected cells)"

	| resultColls allCells subColl coll |
	resultColls := OrderedCollection new.
	allCells := aListOfCells copy.
	subColl := Set new.
	[ allCells isEmpty ] whileFalse: [
		subColl isEmpty ifTrue: [ subColl add: allCells first ].
		coll := (self neighborsOf: subColl) select: [ : aCell |
			        allCells includes: aCell ].
		coll isEmpty
			ifFalse: [ subColl addAll: coll ]
			ifTrue: [
				resultColls add: subColl.
				allCells removeAll: subColl.
				subColl := Set new ] ].
	^ resultColls
]

{ #category : 'testing' }
CMSpatialEntity class >> isCormasCellClass [

	^ true
]

{ #category : 'testing' }
CMSpatialEntity class >> isSpatialClass [
	^ true
]

{ #category : 'utilities' }
CMSpatialEntity class >> neighborsOf: aCollectionOfCells [
	"returns a set of cells that are neighbors of each element of aCollectionOfCells without belonging to aCollectionOfCells"
	
	| neighbors |
	neighbors := Set new.
	aCollectionOfCells do: [:cell | neighbors addAll: cell neighbourhood].
	^Set withAll: (neighbors \ aCollectionOfCells) "\ is a difference between 2 collections: it returns all the elements that are not in aCollectionOfCells"
]

{ #category : 'default value' }
CMSpatialEntity class >> neighbourhood_default [
	
	^OrderedCollection new
]

{ #category : 'instance creation' }
CMSpatialEntity class >> new: aSpaceModel [

	| newEntity |

	newEntity := self new
		             spaceModel: aSpaceModel;
		             cormasModel: aSpaceModel cormasModel;
		             yourself.

	aSpaceModel cormasModel collectEntity: newEntity.
	newEntity initOccupants.

	^ newEntity
]

{ #category : 'default value' }
CMSpatialEntity class >> theOccupants_default [
	
	^Dictionary new
]

{ #category : 'adding' }
CMSpatialEntity >> addOccupant: anObject [

	(self theOccupants at: anObject class name
		ifAbsentPut: [ OrderedCollection new ]) add: anObject
]

{ #category : 'accessing' }
CMSpatialEntity >> aggregates [
"Returns a collection of SpatialEntityAggregates"
	^ aggregates
]

{ #category : 'accessing' }
CMSpatialEntity >> aggregates: anObject [

	aggregates := anObject
]

{ #category : 'environment - sensing - space' }
CMSpatialEntity >> allLayersTo: radius [
	"returns a collection (collResult) of layers :
		- index of collResult is the distance to this layer, 
		- each sub collection is a layer of cells.
radius = integer >= 0.
ex: collResult =	
		[1 ->#(self)
		2 ->#(self neighbourhood)
		3 -> #(layer 2)
		4 -> #(layer 3)  ...]"
	
	| layer1 layer2 collResult |
	collResult := OrderedCollection new: radius.
	layer1 := Array with: self.
	collResult add: layer1.
	radius = 0 ifTrue: [^collResult].
	layer2 := self neighbourhood.
	collResult add: layer2.
	[collResult size < (radius + 1)]
		whileTrue:
			[collResult add: (self layer3FromLayer2: layer2 andLayer1: layer1) first.
			layer2 := collResult last.
			layer1 := collResult at: collResult size - 1].
	^collResult
]

{ #category : 'environment - sensing - agents' }
CMSpatialEntity >> allOccupants [

	^ self theOccupants values flattened
]

{ #category : 'testing' }
CMSpatialEntity >> belongsToAggregate: aSpatialEntity [
"Purpose: tests if the receiver belongs to a higher level spatial entity, even if theCSE is nil. 
This method is valid whatever the aggregate level and even if theCSE is nil. It will return 'true' if the receiver is a component of a component of aSpatialEntity
Argument: aSpatialEntity = <SpatialEntityAggregate>
Return value: <Boolean>"
	
	^aSpatialEntity includesCell: self
]

{ #category : 'accessing' }
CMSpatialEntity >> belongsToAggregateType: aClass [
	"Purpose: returns the instance of a given higher level spatialEntity the receiver belongs to.
Argument:  aClass that must be a subclass of <SpatialEntityAggregate>
Return value: <SpatialEntityAggregate | nil>
Example: self aggregateType: Forest"

^ self aggregates detect: [: a | a isKindOf: aClass] ifNone: [nil]
]

{ #category : 'displaying' }
CMSpatialEntity >> color: aColorSymbol [
	"Purpose: changes background color to a given color (to draw observer attention to the receiver). If aColorSymbol is not a standard Color, it displays the entity in red.
	Argument: aColorSymbol = <ByteSymbol> or <String>
	Example: self color: #pink"
	
	(Color registeredColorNames includes: aColorSymbol asSymbol)
		ifTrue: [ self flashColor: (Color perform: aColorSymbol asSymbol) ]
		ifFalse: [ self flashColor: Color red ]
]

{ #category : 'displaying' }
CMSpatialEntity >> delimitors [
	
	^#nil
]

{ #category : 'initialize-release' }
CMSpatialEntity >> destroyed [
	"Answer if the entity is destroyed or not"
	
	self deprecated: 'Should use #isDestroyed or #isDead '.
	^ destroyed ifNil: [destroyed := false]
]

{ #category : 'initialize-release' }
CMSpatialEntity >> destroyed: aBoolean [
	
	destroyed := aBoolean
]

{ #category : 'environment - distance' }
CMSpatialEntity >> distanceTo: anotherSpatialEntity [
	"Purpose: returns the Manhattan distance (in cells) between the receiver and aSpatialEntity
Argument: anotherSpatialEntity = <SpatialEntity>
Return value: <Integer>"
	
	self subclassResponsibility
]

{ #category : 'environment - distance' }
CMSpatialEntity >> euclideanDistanceTo: anotherSpatialEntity [
	"Purpose: returns the distance between the receiver and another spatialEntity, using the Euclidean distance formula: 
	square root of [(Xa - Xb)^2 + (Ya - Yb)^2)]
Argument: anotherSpatialEntity = <SpatialEntity>"
	
	self subclassResponsibility
]

{ #category : 'displaying' }
CMSpatialEntity >> flashColor: aColorValue [
	"Purpose: changes background color to a given color (to draw observer attention to the receiver). If aColorValue is not a standard Color, it displays the entity in red.
	Argument: aColorValue = <ColorValue> or <String> or <Symbol>
	Example: self flashColor: ColorValue pink or self flashColor: #pink"

	aColorValue isString
		ifTrue: [ ^ self flashColor: (Color perform: aColorValue asSymbol) ].
]

{ #category : 'star displaying' }
CMSpatialEntity >> flashN [

	"Purpose: for each neighours, changes background color to yellow (to draw observer attention to the neighbourhood)"

	self neighbourhood ifNotNil: [ 
		self neighbourhood do: [ :v | v flash ] ]
]

{ #category : 'testing' }
CMSpatialEntity >> hasNoOccupants [

	^ self hasOccupants not
]

{ #category : 'testing' }
CMSpatialEntity >> hasNoOccupantsExcept: anObject [

	self theOccupants ifNil: [ ^ true ].

	^ self theOccupants allSatisfy: [ :list | 
		(list copyWithout: anObject) isEmpty ].
]

{ #category : 'testing' }
CMSpatialEntity >> hasOccupants [

	self theOccupants ifNil: [ ^ false ].

	^ self theOccupants values anySatisfy: [ :list | 
		list isNotEmpty ].
]

{ #category : 'testing' }
CMSpatialEntity >> hasOccupantsOfClass: aClass [

	"Purpose: test if there is an occupant of a given type.
Argument: locatedEntityName = <Symbol | AgentLocation | ObjectLocation>
Return value: <Boolean>
Example: self hasOccupantType: #Tree"

	^ (self occupantsOfClass: aClass) isNotEmpty
]

{ #category : 'initialize-release' }
CMSpatialEntity >> initOccupants [
	
	self allOccupants do: [:a | a leave]
]

{ #category : 'initialization' }
CMSpatialEntity >> initialize [
	" Private - Set the receiver's internal state. Initally a spatial entity is not dead "

	super initialize.

	destroyed := false.
	neighbourhoodWithNils := OrderedCollection new: 8.
	aggregates := OrderedCollection new
]

{ #category : 'printing' }
CMSpatialEntity >> interestingDetails [
	" Answer a <Collection> of interesting receiver's attributes, from a modeler point of view, to display in a popup for example "

	^ super interestingDetails , { 
		'Occupants: ' -> (self theOccupants size) . 
		'Neighbours: ' -> (self neighbourhood size)
		}
]

{ #category : 'testing' }
CMSpatialEntity >> isDead [
	" See superimplementor's comment "

	^ destroyed
]

{ #category : 'testing' }
CMSpatialEntity >> isElementary [
	
	self subclassResponsibility
]

{ #category : 'testing' }
CMSpatialEntity >> isSpatialEntity [
	
	^true
]

{ #category : 'environment - sensing - space' }
CMSpatialEntity >> layer3FromLayer2: aSet2 andLayer1: aSet1 [
	"returns an collection of 2 arrays of cells: layers 3 and 2"
	
	| newLayer |
	newLayer := OrderedCollection new.
	aSet2
		do:
			[:cell | 
			newLayer
				addAll:
					(cell neighbourhood
						select:
							[:c2 | (aSet2 includes: c2) not and: [(aSet1 includes: c2) not]])].
	newLayer := Array withAll: newLayer.
	^OrderedCollection with: newLayer with: aSet2
]

{ #category : 'environment - sensing - space' }
CMSpatialEntity >> layerOfRadius: radius [
	"Purpose: returns the spatial entities belonging to the appropriate layer.of recursive neighbourhood
Argument: radius = <Integer>
Return value: <Collection(SpatialEntity)>"
	
	^(self allLayersTo: radius) last
]

{ #category : 'environment - picking - space' }
CMSpatialEntity >> nearestCellVerifying: aCondition [
	"Purpose: returns the nearest cell verifying a condition specified as aBlock.
Argument: aCondition = <BlockClosure>
Return value: <SpatialEntity | nil>
Generic method to be used for polygonal cells and compound spatial entities. For cells (elementary square or hexagonal spatial entities), see methods in class SpatialEntitryElement 
Example := self nearestCellVerifying: [:aCell | aCell landCover = #water]"
	
	^self
		nearestCellVerifying: aCondition
		constraintOnPath: [:aCell | true]
]

{ #category : 'environment - picking - space' }
CMSpatialEntity >> nearestCellVerifying: condition1 constraintOnPath: condition2 [
	"Purpose: returns the nearest cell verifying a specified condition1, the cells in between verifying another specified condition2.
Arguments: condition1 = <BlockClosure>
			condition2 = <BlockClosure>
Return value: <SpatialEntity | nil>
Generic method to be used for polygonal cells and compound spatial entities. For cells (elementary square or hexagonal spatial entities), see methods in class SpatialEntitryElement 
Example := self nearestCellVerifying: [:aCell | aCell hasWater] constraintOnPath: [:aCell | aCell isClosed not]"
	
	self subclassResponsibility
]

{ #category : 'environment - picking - space' }
CMSpatialEntity >> nearestEmptyNeighborWithinRadius: range [
	"Returns the nearest spatial entity within a given radius and with no occupant of any kind. If none: returns nil; if more than one at the minimum radius: random selection"
	
	| locations |
	locations := self nearestEmptyNeighborsWithinRadius: range.
	
	^ locations
		ifNotEmpty: [ self selectRandomlyFrom: locations ]
		ifEmpty: [ nil ]
]

{ #category : 'environment - sensing - space' }
CMSpatialEntity >> nearestEmptyNeighborsWithinRadius: range [
	"Purpose: returns the nearest spatial entities within a given radius and with no occupant of any kind.
Argument: range = <Integer>
Return value: <Collection(SpatialEntity)>"
	
	^self
		nearestNeighborsVerifying: [ :n | n hasNoOccupants ]
		withinRadius: range
]

{ #category : 'environment - picking - space' }
CMSpatialEntity >> nearestNeighborVerifying: aBlock withMaxOf: aMagnitudeName withinRadius: range [
	"Returns the nearest spatial entity verifying a specified condition with the higest value of a given function in a given radius. 
The current location is NOT considered. If none: returns nil; if more than one with the highest value at the minimum radius: random selection "
	
	| locations |
	locations := self nearestNeighborsVerifying: aBlock withMaxOf:
			aMagnitudeName withinRadius: range.
			
	^ locations
		ifNotEmpty: [ self selectRandomlyFrom: locations ]
		ifEmpty: [ nil ]
]

{ #category : 'environment - picking - space' }
CMSpatialEntity >> nearestNeighborVerifying: aBlock withinRadius: range [
	"Returns the nearest spatial entity within a given radius and fulfilling a specified constraint. If none: returns nil; if more than one at the minimum radius: random selection"
	
	| locations |
	locations := self nearestNeighborsVerifying: aBlock withinRadius: range.
	
	^ locations
		ifNotEmpty: [ self selectRandomlyFrom: locations ]
		ifEmpty: [ nil ]
]

{ #category : 'environment - picking - space' }
CMSpatialEntity >> nearestNeighborWithMaxOf: aMagnitudeName withinRadius: range [
	"Returns the nearest spatial entity with the higest value of a given function in a given radius. 
The current location is NOT considered
If none: returns nil; if more than one with the highest value at the minimum radius: random selection"
	
	| locations |
	locations := self nearestNeighborsWithMaxOf: aMagnitudeName withinRadius:
			range.
			
	^ locations
		ifNotEmpty: [ self selectRandomlyFrom: locations ]
		ifEmpty: [ nil ]
]

{ #category : 'environment - picking - space' }
CMSpatialEntity >> nearestNeighborWithoutAny: locatedEntityName withinRadius: range [
	"Returns the nearest spatial entity in a given range without any occupant of a given type. 
If none: returns nil; if more than one at the minimum radius: random selection"
	
	| locations |
	locations := self nearestNeighborsWithoutAny: locatedEntityName
		withinRadius: range.
		
	^ locations
		ifNotEmpty: [ self selectRandomlyFrom: locations ]
		ifEmpty: [ nil ]
]

{ #category : 'environment - sensing - space' }
CMSpatialEntity >> nearestNeighborsVerifying: aCondition withMaxOf: aMagnitudeName withinRadius: range [
	"Purpose: returns the nearest spatial entities within a given radius of the current location with the maximum value of a given magnitude and verifying a specified condition. 
The current location is NOT considered
Arguments: aMagnitudeName = <ByteSymbol>
			aCondition = <BlockClosure>
			range = <Integer>
Return value: <Collection(SpatialEntity)>
Example: self nearestNeighborsWithMaxOf: #water verifying: [:c | c isPolluted not] withinRadius: 5"

	| locations |
	locations := self
		             selectEntitiesWithMaxOf: aMagnitudeName
		             amongEntities: (self recursiveNeighbourhood: range)
		             verifying: aCondition.
	locations remove: self ifAbsent: [  ].
	locations := locations asSortedCollection: [ :i :j |
		             (i distanceTo: self) < (j distanceTo: self) ].
	locations := locations select: [ :c |
		             (c distanceTo: self)
		             = (locations first distanceTo: self) ].
	^ locations
]

{ #category : 'environment - sensing - space' }
CMSpatialEntity >> nearestNeighborsVerifying: aBlock withinRadius: range [
	"Purpose: returns the nearest spatial entities within a given radius and fulfilling a specified constraint.
Arguments: range = <Integer>
			aBlock = <BlockClosure>
Return value: <Collection(SpatialEntity)>
Example: self nearestNeighborsVerifying: [:c | c isClosed not] withinRadius: 7"
	
	| locations n |
	locations := OrderedCollection new.
	n := 1.
	[locations isEmpty and: [n <= range]]
		whileTrue:
			[locations := self recursiveNeighbourhood: n verifying: aBlock.
			n := n + 1].
	locations
		remove: self
		ifAbsent: [].
	^locations
]

{ #category : 'environment - sensing - space' }
CMSpatialEntity >> nearestNeighborsWithMaxOf: aMagnitudeName withinRadius: range [
	"Purpose: returns the nearest spatial entities within a given radius of the current location with the maximum value of a given magnitude. 
The current location is NOT considered
Arguments: aMagnitudeName = <ByteSymbol>
			range = <Integer>
Return value: <Collection(SpatialEntity)>
Example: self nearestNeighborsWithMaxOf: #water withinRadius: 5"
	
	^self
		nearestNeighborsVerifying: [:c | true]
		withMaxOf: aMagnitudeName
		withinRadius: range
]

{ #category : 'environment - sensing - space' }
CMSpatialEntity >> nearestNeighborsWithoutAny: aClass withinRadius: range [
	"Purpose: returns the nearest spatial entities within a given radius and without any occupant of a given type.
Return value: <Collection(SpatialEntity)>
Example: self nearestNeighborsWithoutAny: #Tree withinRadius: 5 "
	
	^self
		nearestNeighborsVerifying: [:p | (p hasOccupantsOfClass: aClass) not ]
		withinRadius: range
]

{ #category : 'environment - sensing - space' }
CMSpatialEntity >> neighborsStringWithSeparator: aChar [

	"Purpose: returns a string made of 'self id' as first element and the id of all neighbors separated by aChar
Argument: aChar = <Character>
Return value: <ByteString>"

	| string |
	string := self id printString.
	self neighbourhood ifNotNil: [ 
		self neighbourhood do: [ :i | 
			string := string , aChar asSymbol asString , i id printString ] ].
	^ string
]

{ #category : 'environment - sensing - space' }
CMSpatialEntity >> neighbourhood [
	"If the cell is located at the edge or in the corner of a closed (non-torroidal) envionment, the missing neighbours are represented as nils. Here we remove them to get only the list of neighbours"
	
	^ neighbourhoodWithNils reject: [ :each | each isNil ]
]

{ #category : 'environment - sensing - space' }
CMSpatialEntity >> neighbourhoodAndSelf [
	"Purpose: returns the spatial entities belonging to the direct neighbourhood of the receiver
Also includes the receiver itself
self neighbourhoodAndSelf == self recursiveNeighbourhood: 1
Return value: <Collection(SpatialEntity)>"
	
	| collec |
	collec := self neighbourhood asOrderedCollection.
	collec addFirst: self.
	^collec asArray
]

{ #category : 'environment - sensing - space' }
CMSpatialEntity >> neighbourhoodWithNils [
	
	^ neighbourhoodWithNils
]

{ #category : 'environment - sensing - space' }
CMSpatialEntity >> neighbourhoodWithNils: aCollection [
	"If the cell is located at the edge or in the corner of a closed (non-torroidal) envionment, the missing neighbours are represented as nils"
	
	neighbourhoodWithNils := aCollection
]

{ #category : 'environment - sensing - agents' }
CMSpatialEntity >> occupantsOfClass: aClass [

	"Purpose: returns all the entities of a given type located there
Note that the instances of subclasses ARE CONSIDERED by this method
Return value: <Collection(AgentLocation & ObjectLocation)>"
	
	aClass ifNil: [ ^ OrderedCollection new ].
	
	^ aClass withAllSubclasses flatCollect: [ :eachClass |
		self theOccupants
			at: eachClass name
			ifAbsent: [ OrderedCollection new ] ].
]

{ #category : 'environment - sensing - agents' }
CMSpatialEntity >> occupantsOfClassNamed: aClassName [

	"Purpose: returns all the entities of a given class name located there
Return value: <Collection(AgentLocation & ObjectLocation)>"

	| aClass |
	aClass := self class environment at: aClassName asSymbol.
	^ self occupantsOfClass: aClass
]

{ #category : 'printing' }
CMSpatialEntity >> printOn: aStream [
	" Private - See superimplementor's comment "
	
	super printOn: aStream.
	aStream
		space; 
		<< $-;
		<< 'n: ';
		<< self neighbourhood size asString;
		space;
		<< $-;
		<< 'o: ';
		<< self theOccupants size asString
]

{ #category : 'environment - picking - space' }
CMSpatialEntity >> randomNeighbour [
	
	^ self selectRandomlyFrom: self neighbourhood
]

{ #category : 'environment - picking - space' }
CMSpatialEntity >> randomNeighbourVerifying: aCondition [
	"Returns a neighbour randomly chosen among those verifying a given condition"
	
	| candidates |
	candidates := self neighbourhood select: [ :each | aCondition value: each ].
	
	^ candidates
		ifEmpty: [ nil ]
		ifNotEmpty: [ self selectRandomlyFrom: candidates ]
]

{ #category : 'environment - sensing - space' }
CMSpatialEntity >> recursiveNeighbourhood: radius [
	"Purpose: returns a collection of receiver-like spatial entities within a given radius of the receiver.
The receiver itself is included in the collection, which is ordered from the center (self) to the perimeter of the radius.
Argument: radius = <Integer>
Return value: <OrderedCollection>
Example: self recursiveNeighbourhood: 0 (== OrderedCollection with: self)
Example: self recursiveNeighbourhood: 1 (== self neighbourhoodAndSelf)"
	
	| allCells layers |
	allCells := OrderedCollection new.
	layers := self allLayersTo: radius.
	layers do: [:layer | allCells addAll: layer].
	^allCells
]

{ #category : 'environment - sensing - space' }
CMSpatialEntity >> recursiveNeighbourhood: range verifying: aBlock [
	"Purpose: returns the spatial entities within a given radius and fulfilling the constraint specified in aBlock. 
Arguments: range = <Integer>
			aBlock = <BlockClosure>
Return value: <Collection(SpatialEntity)>
Example: self recursiveNeighbourhood: 5 verifying: [:c | c isClosed not] "
	
	^(self recursiveNeighbourhood: range) select: [:p | aBlock value: p]
]

{ #category : 'environment - sensing - space' }
CMSpatialEntity >> recursiveNeighbourhood: range withoutAny: aClass [
	"Purpose: returns the spatial entities within a given radius and without any occupant of a given type.
Return value: <Collection(SpatialEntity)>
Example: self recursiveNeighbourhood: 5 withoutAny: #Tree"
	
	^self
		recursiveNeighbourhood: range
		verifying: [:p | (p hasOccupantsOfClass: aClass) not ]
]

{ #category : 'initialize-release' }
CMSpatialEntity >> release [
	"Free my dependents "
	
	destroyed := true.
	^super release
]

{ #category : 'utilities - collection' }
CMSpatialEntity >> selectEntitiesWithMaxOf: aMagnitudeName amongEntities: aCollection verifying: aCondition [
	"Selects the entities with the maximum value of a given magnitude and verifying a specified condition"

	| selection |
	selection := aCollection select: [ :c |
		             ((c perform: aMagnitudeName) respondsTo: #>) and: [
			             aCondition value: c ] ].
	selection := selection asSortedCollection: [ :i :j |
		             (i perform: aMagnitudeName)
		             > (j perform: aMagnitudeName) ].
	selection := selection select: [ :c |
		             (c perform: aMagnitudeName)
		             = (selection first perform: aMagnitudeName) ].
	^ selection
]

{ #category : 'environment - distance' }
CMSpatialEntity >> shortestDistanceToCells: aCollecOfCells constraintOnPath: aBlock [
	"Purpose: gets the shortest distance (in cell unit) to a collection of other cells, taking a specified constraint into account.
Arguments: aCollecOfCells = <Collection(SpatialEntityElement)>
			aBlock = <BlockClosure>
Return value: <Integer>
Example: self shortestDistanceToCells: self myPlots constraintOnPath: [:aCell | aCell isClosed not]"
	
	self subclassResponsibility
]

{ #category : 'environment - distance' }
CMSpatialEntity >> shortestDistanceToCellsVerifying: aCondition [
	"Purpose: gets the shortest distance (in cell unit) to a cell verifying a specified condition.
Arguments: aCondition = <BlockClosure>
Return value: <Integer>
Example: self shortestDistanceToCellVerifying: [:c | c landCover = #forest]"
	
	self subclassResponsibility
]

{ #category : 'environment - distance' }
CMSpatialEntity >> shortestDistanceToCellsVerifying: aCondition constraintOnPath: aBlock [

	"Purpose: gets the shortest distance (in cell unit) to a cell verifying a specified condition, taking a specified constraint on the path into account.
Arguments: aCondition = <BlockClosure>
			aBlock = <BlockClosure>
Return value: <Integer>
Example: self shortestDistanceToCellVerifying: [:c | c landCover = #forest] constraintOnPath: [:c | c isClosed not]"

	| targetCell |
	targetCell := self
		              nearestCellVerifying: aCondition
		              constraintOnPath: aBlock.
	^ targetCell
		  ifNil: [ self error: 'there is no nearest cell' ]
		  ifNotNil: [ self distanceTo: targetCell ]
]

{ #category : 'accessing' }
CMSpatialEntity >> spaceModel [
	
	^ spaceModel
]

{ #category : 'accessing' }
CMSpatialEntity >> spaceModel: aSpaceModel [
	
	spaceModel := aSpaceModel
]

{ #category : 'accessing' }
CMSpatialEntity >> theOccupants [
	
	^theOccupants ifNil: [theOccupants := Dictionary new]
]

{ #category : 'accessing' }
CMSpatialEntity >> theOccupants: aDict [
	
	theOccupants := aDict
]

{ #category : 'environment - sensing - space' }
CMSpatialEntity >> wayTo: anotherSpatialEntity [
	"Purpose: returns one of the shortest path to another spatial entity
Argument: anotherSpatialEntity = <SpatialEntity>"
	
	self subclassResponsibility
]
