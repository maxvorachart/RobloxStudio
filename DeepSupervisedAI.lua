local DataStoreService = game:GetService("DataStoreService")

local neuralNetworksData = DataStoreService:GetDataStore("NeuralNetworksData")

local key = 5
local save = true
local learningRate = 0.1

local neuralNetwork = {}


local function initializeLayer(numNeurons, numWeights)
	local layer = {}
	
	for i = 1, numNeurons do
		local neuron = {}
		
		neuron.bias = math.random() * 2 - 1
		
		neuron.weights = {}
		
		for i = 1, numWeights do
			table.insert(neuron.weights, math.random() * 2 - 1)
		end
		
		table.insert(layer, neuron)
	end
	
	table.insert(neuralNetwork, layer)
end

function sigmoid(x)
	return 1 / (1 + math.exp(-x))
end

function sigmoidDerivative(x)
	local sig = sigmoid(x)
	return sig * (1 - sig)
end

local inputLayer = 50
local hiddenLayer1 = 64
local hiddenLayer2 = 64
local hiddenLayer3 = 64
local outputLayer = 9

if save then
	local success, savedNeuralNetwork = pcall(function()
		return neuralNetworksData:GetAsync(key)
	end)
	
	if success and savedNeuralNetwork then
		neuralNetwork = savedNeuralNetwork
	else
		initializeLayer(hiddenLayer1, inputLayer)
		initializeLayer(hiddenLayer2, hiddenLayer1)
		initializeLayer(hiddenLayer3, hiddenLayer2)
		initializeLayer(outputLayer, hiddenLayer3)
	end
else
	initializeLayer(hiddenLayer1, inputLayer)
	initializeLayer(hiddenLayer2, hiddenLayer1)
	initializeLayer(hiddenLayer3, hiddenLayer2)
	initializeLayer(outputLayer, hiddenLayer3)
end



local function forwardPass(input)
	local activations = {input}
	
	for i, layer in ipairs(neuralNetwork) do
		local currentLayer = {}
		
		for _, neuron in ipairs(layer) do
			local activation = neuron.bias
			
			for j, weight in ipairs(neuron.weights) do
				activation += activations[i][j] * weight
			end
			
			activation = sigmoid(activation)
			
			table.insert(currentLayer, activation)
		end
		
		table.insert(activations, currentLayer)
	end

	return activations
end

local function backPropogate(answer, activations)
	local deltas = {}
	
	local outputDelta = {}
	
	for i, neuron in ipairs(neuralNetwork[#neuralNetwork]) do
		
		local activation = activations[#activations][i]
		
		local error = (answer == i and 1 or 0) - activation
		
		local delta = error * sigmoidDerivative(activation)
		
		table.insert(outputDelta, delta)
	end
	
	table.insert(deltas, outputDelta)
	
	for i = #neuralNetwork - 1, 1, - 1 do
		local layer = neuralNetwork[i]
		local nextLayer = neuralNetwork[i + 1]
		local layerDelta = {}
		
		for j, neuron in ipairs(layer) do
			local error = 0
			
			for k, nextNeuron in ipairs(nextLayer) do
				error += deltas[1][k] * nextNeuron.weights[j]
			end
			
			local delta = error * sigmoidDerivative(activations[i + 1][j])
			
			table.insert(layerDelta, delta)
		end
		
		table.insert(deltas, 1, layerDelta)
	end
		
	for i, layer in ipairs(neuralNetwork) do
		for j, neuron in ipairs(layer) do

			neuron.bias += deltas[i][j] * learningRate
			
			for k, weight in ipairs(neuron.weights) do
				neuron.weights[k] += deltas[i][j] * activations[i][k] * learningRate
			end
		end
	end
end

local memory = {}
local score = {}

for i = 1, inputLayer do
	table.insert(memory, 0)
end

for i = 1, 100 do
	table.insert(score, false)
end

while task.wait() do
	local chance = math.random(1, 10000)
	local reward
	
	-- Super Raffle (3%)
	if chance <= 30 then  -- 3% of 10000 is 300
		local superChance = math.random(1, 1000)
		if superChance <= 190 then
			reward = 6  -- 19% of Super Raffle for item 1 (0.57%)
		elseif superChance <= 610 then
			reward = 7  -- 42% of Super Raffle for item 2 (1.26%)
		elseif superChance <= 950 then
			reward = 8  -- 34% of Super Raffle for item 3 (1.02%)
		else
			reward = 9  -- 5% of Super Raffle for item 4 (0.15%)
		end
	else
		-- Normal Raffle (97%)
		chance = chance - 300  -- Adjust chance to range from 1 to 9700
		if chance <= 3300 then
			reward = 1  -- 33% for item 5
		elseif chance <= 6100 then
			reward = 2  -- 28% for item 6 (6100 - 3300 = 2800 or 28%)
		elseif chance <= 6400 then
			reward = 3  -- 3% for item 7 (6400 - 6100 = 300 or 3%)
		elseif chance <= 9000 then
			reward = 4  -- 26% for item 8 (9000 - 6400 = 2600 or 26%)
		else
			reward = 5  -- 10% for item 9 (10000 - 9000 = 1000 or 10%)
		end
	end
	
	table.insert(memory, reward)
	table.remove(memory, 1)
	
	local activations = forwardPass(memory)
	
	local highestValue = -math.huge
	local guess
	
	for i, value in pairs(activations[#activations]) do
		if value > highestValue then
			highestValue = value
			guess = i
		end
	end
	
	table.insert(score, reward == guess)
	table.remove(score, 1)
	
	local numCorrect = 0
	
	for _, isCorrect in pairs(score) do
		if isCorrect then
			numCorrect += 1
		end
	end
	
	local percentScore = numCorrect / 100
	
	print(percentScore)
	--print(reward, guess)
	--print(reward == guess)
	
	backPropogate(reward, activations)
	
end

game:BindToClose(function()
	if not save then return end
	
	local success, error = pcall(function()
		neuralNetworksData:SetAsync(key, neuralNetwork)
	end)
end)