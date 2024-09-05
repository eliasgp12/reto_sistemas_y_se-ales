function VoiceRecognitionInterface
    % Crear la figura principal
    f = figure('Position', [500, 300, 400, 400], 'Name', 'Reconocimiento de Voz', 'NumberTitle', 'off');
    
    % Cargar la imagen de fondo
    img = imread('/Users/eliasguerra/Downloads/tuca.jpeg'); 

    % Obtener las dimensiones de la imagen
    [imgHeight, imgWidth, ~] = size(img);
    
    % Calcular las posiciones para centrar la imagen
    figWidth = f.Position(3);
    figHeight = f.Position(4);
    imgXPos = (figWidth - imgWidth) / 2; % Posición X para centrar la imagen
    imgYPos = (figHeight - imgHeight) / 2; % Posición Y para centrar la imagen

    % Crear el eje para la imagen de fondo en el centro
    backgroundAxes = axes('Parent', f, 'Position', [imgXPos/figWidth, imgYPos/figHeight - 0.1, imgWidth/figWidth, imgHeight/figHeight]);
    uistack(backgroundAxes, 'bottom');  % Mover el eje al fondo
    imshow(img, 'Parent', backgroundAxes, 'InitialMagnification', 'fit');

    % Ocultar los ejes de la imagen
    set(backgroundAxes, 'XTick', [], 'YTick', [], 'Box', 'off');

    % Añadir la frase "oye tuca" en la parte superior
    uicontrol('Style', 'text', 'String', 'Oye Tuca', ...
        'Position', [50, 350, 300, 30], 'HorizontalAlignment', 'center', ...
        'FontSize', 18, 'FontWeight', 'bold', 'Parent', f);

    % Crear el botón para grabar
    recordButton = uicontrol('Style', 'pushbutton', 'String', 'Grabar', ...
        'Position', [100, 250, 200, 50], 'Callback', @recordAudio, 'Parent', f);
    
    % Crear el botón para predecir
    predictButton = uicontrol('Style', 'pushbutton', 'String', 'Predecir', ...
        'Position', [100, 180, 200, 50], 'Callback', @predictVoice, 'Parent', f);
    
    % Crear una etiqueta para mostrar la predicción
    predictionLabel = uicontrol('Style', 'text', 'String', 'Predicción:', ...
        'Position', [50, 100, 300, 50], 'HorizontalAlignment', 'left', 'FontSize', 12, 'Parent', f);
    
    % Variables globales para almacenar los datos
    global audioIn fs nBits nChannels duration trainedClassifier M S;
    
    % Parámetros de grabación
    fs = 44100;  % Frecuencia de muestreo
    nBits = 16;  % Resolución en bits
    nChannels = 1;  % Canales (monofónico)
    duration = 2;  % Duración de la grabación
    
    % Definir los umbrales de energía y zcr
    energyThreshold = 0.02;  % Umbral para la energía
    zcrThreshold = 0.38;    % Umbral para la tasa de cruces por cero
    
    % Cargar el clasificador entrenado, M y S
    load('/Users/eliasguerra/Documents/normalizedFeatures.mat', 'trainedClassifier', 'M', 'S');

    % Función para grabar audio
    function recordAudio(~, ~)
        recObj = audiorecorder(fs, nBits, nChannels);
        disp('Comienza a hablar por 2 segundos...');
        recordblocking(recObj, duration);
        disp('Fin de la grabación.');
        audioIn = getaudiodata(recObj);

        % Reproducir el audio grabado (opcional)
        sound(audioIn, fs);
    end

    % Función para predecir la voz
    function predictVoice(~, ~)
        % Verifica si el audio ha sido grabado
        if isempty(audioIn)
            disp('Error: No se ha grabado ningún audio.');
            return;
        end

        % Definir los parámetros de la ventana
        windowLength = round(0.03 * fs);   % Largo de ventana (30 ms)
        overlapLength = round(0.025 * fs); % Solapamiento (25 ms)

        % Crear un extractor de características similar al usado en el entrenamiento
        afe = audioFeatureExtractor(SampleRate=fs, ...
    Window=hamming(windowLength,"periodic"),OverlapLength=overlapLength, ...
    zerocrossrate=true,shortTimeEnergy=true,pitch=true,mfcc=true);

        % Extraer las características del audio grabado
        featureMap = info(afe);
        inputFeatures = extract(afe, audioIn);
        
        % Filtrar las características de voz
        isSpeech = inputFeatures(:, featureMap.shortTimeEnergy) > energyThreshold;
        isVoiced = inputFeatures(:, featureMap.zerocrossrate) < zcrThreshold;
        voicedSpeech = isSpeech & isVoiced;
        
        % Filtrar las características no necesarias
        inputFeatures(~voicedSpeech, :) = [];
        inputFeatures(:, [featureMap.zerocrossrate, featureMap.shortTimeEnergy]) = [];

        % Normalizar las características (si las dimensiones coinciden)
        if size(inputFeatures, 2) == size(M, 2) && size(inputFeatures, 2) == size(S, 2)
            inputFeatures = (inputFeatures - M) ./ S;

            % Realizar las predicciones para cada vector de características
            predictedLabels = predict(trainedClassifier, inputFeatures);

            % Contar la clase que aparece más veces
            finalLabel = mode(predictedLabels);

            % Mostrar el resultado final en la interfaz
            set(predictionLabel, 'String', ['Predicción: ', finalLabel]);
        else
            set(predictionLabel, 'String', 'Error: Las dimensiones no coinciden.');
        end
    end
end
