% Define la carpeta donde están los archivos originales
carpetaEntrada = "C:\Users\salga\OneDrive\Documentos\Variación_de_voces\yestli";
carpetaSalida = carpetaEntrada;

% Obtiene la lista de archivos WAV en la carpeta
archivosAudio = dir(fullfile(carpetaEntrada, '*.wav'));

% Se prepara el aumentador
aumentador = audioDataAugmenter( ...
    "AugmentationMode","sequential", ...
    'AugmentationParameterSource','random', ...
    "NumAugmentations",9, ... % Generar 9 copias por archivo
    "TimeStretchProbability",0.8, ...
    "SpeedupFactorRange",[1.3,1.4], ...
    "PitchShiftProbability",0, ...
    "VolumeControlProbability",0.8, ...
    "VolumeGainRange",[-5,5], ...
    "AddNoiseProbability",0.5, ...
    "SNRRange",[0,20], ...
    "TimeShiftProbability",0.8, ...
    "TimeShiftRange",[-500e-3,500e-3]);

% Procesa cada archivo de audio en la carpeta
for idx = 1:length(archivosAudio)
    % Lee el archivo de audio
    rutaArchivoAudio = fullfile(carpetaEntrada, archivosAudio(idx).name);
    [audioOriginal, frecuenciaMuestreo] = audioread(rutaArchivoAudio);
    
    % Aplica el aumentador
    datosAumentados = augment(aumentador, audioOriginal, frecuenciaMuestreo);
    
    % Guarda los audios aumentados en la misma carpeta
    [~, nombreArchivo, extension] = fileparts(archivosAudio(idx).name); % Obtiene el nombre base del archivo
    for j = 1:height(datosAumentados)
        audioAumentado = datosAumentados.Audio{j};
        nombreArchivoSalida = fullfile(carpetaSalida, sprintf("%s_aumentado_%d%s", nombreArchivo, j, extension));
        audiowrite(nombreArchivoSalida, audioAumentado, frecuenciaMuestreo);
    end
end
