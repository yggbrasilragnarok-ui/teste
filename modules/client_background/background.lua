-- private variables
local background
local clientVersionLabel

-- Variáveis da Animação
local animEvent = nil
local currentFrame = 1
local maxFrames = 178   -- [CONFIG] SEU NÚMERO DE FRAMES (178)
local animSpeed = 50    -- [CONFIG] Velocidade em ms
local frameCache = {}   -- Tabela para guardar as imagens na memória

-- [NOVO] Função que pré-carrega as imagens para a memória RAM
function cacheBackgroundImages()
  -- Se já carregou, não faz de novo
  if #frameCache > 0 then return end

  for i = 1, maxFrames do
    local path = '/images/background_' .. i .. '.png'
    
    -- Tenta carregar na memória de vídeo/RAM
    if g_textures.preload then
        g_textures.preload(path)
    end
    
    -- Salva o caminho na tabela para acesso rápido
    frameCache[i] = path
  end
end

-- Funções da Animação
function startBackgroundAnimation()
  if animEvent then return end -- Já está rodando, não faz nada
  cycleBackground()
end

function stopBackgroundAnimation()
  if animEvent then
    removeEvent(animEvent)
    animEvent = nil
  end
end

function cycleBackground()
  -- Se o painel 'background' não existir ou não estiver visível, para.
  if not background or not background:isVisible() then return end
  
  -- Tenta achar o widget onde a imagem deve aparecer
  local animationWidget = background:recursiveGetChildById('background') 
  
  -- Se não achar pelo ID 'background', tenta usar a própria janela principal
  if not animationWidget then 
    animationWidget = background 
  end

  if animationWidget then
    -- [MUDANÇA] Usa a imagem do CACHE em vez de concatenar string toda hora
    local imagePath = frameCache[currentFrame]
    
    -- Fallback de segurança: se o cache falhou, tenta montar o nome na hora
    if not imagePath then
        imagePath = '/images/background_' .. currentFrame .. '.png'
    end

    animationWidget:setImageSource(imagePath)
    
    -- Avança o frame
    currentFrame = currentFrame + 1
    if currentFrame > maxFrames then
      currentFrame = 1
    end
    
    -- Agenda a próxima troca
    animEvent = scheduleEvent(cycleBackground, animSpeed)
  end
end

-- Funções Principais do Módulo
function init()
  -- Carrega o arquivo .otui
  background = g_ui.displayUI('background')
  background:lower()

  -- [IMPORTANTE] Carrega as imagens na memória assim que o módulo inicia
  cacheBackgroundImages()

  -- Configura o texto da versão
  clientVersionLabel = background:getChildById('clientVersionLabel')
  if clientVersionLabel then
      clientVersionLabel:setText(g_app.getName() .. ' ' .. g_app.getVersion() .. '\n' ..
                               'Rev  ' .. g_app.getBuildRevision() .. ' ('.. g_app.getBuildCommit() .. ')\n' ..
                               'Built on ' .. g_app.getBuildDate() .. '\n' .. g_app.getBuildCompiler())
      
      if not g_game.isOnline() then
        addEvent(function() g_effects.fadeIn(clientVersionLabel, 1500) end)
      end
  end

  -- Hooks de Login/Logout
  connect(g_game, { onGameStart = hide })
  connect(g_game, { onGameEnd = show })
  
  -- Inicia a animação se não estiver online
  if not g_game.isOnline() then
      startBackgroundAnimation()
  end
end

function terminate()
  disconnect(g_game, { onGameStart = hide })
  disconnect(g_game, { onGameEnd = show })

  stopBackgroundAnimation()

  if clientVersionLabel then
    g_effects.cancelFade(clientVersionLabel)
  end
  
  if background then
    background:destroy()
    background = nil
  end
  
  -- Limpa o cache para liberar memória (opcional, bom se tiver pouca RAM)
  frameCache = {}
  
  Background = nil
end

function hide()
  stopBackgroundAnimation() -- Para a animação ao entrar no jogo (economiza PC)
  if background then background:hide() end
end

function show()
  if background then 
      background:show() 
      startBackgroundAnimation() -- Retoma a animação ao deslogar
  end
end

function hideVersionLabel()
  if clientVersionLabel then clientVersionLabel:hide() end
end

function setVersionText(text)
  if clientVersionLabel then clientVersionLabel:setText(text) end
end

function getBackground()
  return background
end