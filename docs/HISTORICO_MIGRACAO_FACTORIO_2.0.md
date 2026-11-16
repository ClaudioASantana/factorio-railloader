# Histórico de Migração: Factorio 1.1 → Factorio 2.0 / 2.1
**Mod:** Bulk Rail Loader (`railloader`)  
**Versão:** 2.1.0  
**Data:** 10/11/2026  
**Repositório Fork:** [ClaudioASantana/factorio-railloader](https://github.com/ClaudioASantana/factorio-railloader)  
**Branch de trabalho:** `factorio-2.0`

---

## 1. Contexto Inicial

Ao tentar carregar o mod no Factorio 2.1.24 (Space Age), o jogo abortava logo no início com o erro:
```
Falha ao carregar mods: __railloader__/prototypes/entity/pictures.lua:13: attempt to call global 'rail_pictures' (a nil value)
```

O objetivo foi adaptar todas as definições de protótipos (Data Stage) e os scripts em tempo de execução (Control Stage / Runtime) para serem compatíveis com o Factorio 2.0 / 2.1.

---

## 2. Alterações na Fase de Protótipos (Data Stage)

### 2.1 `prototypes/entity/pictures.lua`
- **Remoção de `rail_pictures()`**: No Factorio 2.0 a função global `rail_pictures` foi removida. O mod agora lê diretamente `data.raw["straight-rail"]["straight-rail"].pictures`.
- **Mapeamento de Direções**: As chaves direcionais de trilho reto mudaram de `"horizontal"` / `"vertical"` para `"east"` / `"north"`.
- **Remoção de `hr_version`**: O Factorio 2.0 usa texturas em alta resolução nativamente, definindo `scale = 0.5`. Todas as tabelas `hr_version` foram unificadas.
- **Gráficos de Vagões e Rodas**:
  - `cargo_wagon.pictures.layers` mudou para `cargo_wagon.pictures.rotated.layers`.
  - `cargo_wagon.wheels` mudou para `cargo_wagon.wheels.rotated`.
- **Sprites Vazios**: `M.empty_sheet` e `M.empty_animation` agora usam `util.empty_sprite()` e `util.empty_animation()`.

### 2.2 `prototypes/entity/circuitconnectors.lua`
- **Substituição de `circuit_connector_definitions.create`**: No Factorio 2.0 a função foi substituída por `circuit_connector_definitions.create_vector`.

### 2.3 `prototypes/entity/railloader.lua` e `railunloader.lua`
- **Volume no FluidBox da Bomba**: `fluid_box` da entidade proxy (tipo `pump`) agora exige o campo `volume = 100`.
- **Formato de Collision Mask**: Substituído o formato antigo de array de strings (`{"item-layer", ...}`) pelo formato do Factorio 2.0 com `CollisionMaskConnector`:
  ```lua
  collision_mask = {
    layers = {
      item = true,
      object = true,
      water_tile = true,
      is_object = true,
      is_lower_object = true
    }
  }
  -- Máscaras vazias:
  collision_mask = { layers = {} }
  ```
- **Inserter Prototype**: Propriedade `stack = true` substituída por `bulk = true`.
- **Circuit Connectors**: `circuit_wire_connection_points` e `circuit_connector_sprites` foram consolidados na propriedade única `circuit_connector`.

### 2.4 `prototypes/recipe/Recipe.lua`, `railloader.lua` e `railunloader.lua`
- **Normalização de Receitas**:
  - `result = "railloader"` migrado para `results = {{type = "item", name = "railloader", amount = 1}}`.
  - Ingredientes normalizados para `{type = "item", name = "...", amount = ...}`.
  - Adicionada verificação preventiva contra tabelas nulas de tipos de itens ao checar receitas de mods opcionais.

### 2.5 `info.json`
- `factorio_version` atualizado para `"2.0"`.

---

## 3. Alterações na Fase de Scripts (Control / Runtime Stage)

### 3.1 Substituição de `global` por `storage`
No Factorio 2.0, a tabela global do Lua foi renomeada de `global` para `storage`.
- **`control.lua`**: `storage.previous_opened_blueprint_for`.
- **`configchange.lua`**: Todas as 10 referências em migrações migradas para `storage`.
- **`EntityQueue.lua`**: Todas as 14 referências de indexação `storage[self.name]` migradas.
- **`spec/EntityQueue_spec.lua`**: Mock de testes atualizado para `storage = {}`.
- *(Nota: `settings.global[...]` foi mantido intacto pois faz parte da API oficial de configurações).*

### 3.2 `LuaEntity::minable` Read-Only
No Factorio 2.0, `entity.minable` tornou-se apenas leitura.
- Em `control.lua:159` e nas migrações, a escrita para desativar mineração de trilhos foi alterada de:
  ```lua
  rail.minable = false
  ```
  para:
  ```lua
  rail.minable_flag = false
  ```

### 3.3 Nova API de Circuitos (`LuaWireConnector`)
No Factorio 2.0, os métodos `LuaEntity::connect_neighbour` e a propriedade `circuit_connection_definitions` foram removidos.
- **Nova função utilitária `util.transfer_circuit_connections(source, target)`**:
  Lê os conectores de fio da entidade de origem (`source.get_wire_connectors(false)`) e reconecta suas conexões ativas diretamente na entidade de destino (`target.get_wire_connector(id, true).connect_to(...)`).
- **Conexão interna do Inserter com o Chest**:
  Usa `inserter.get_wire_connector(defines.wire_connector_id.circuit_red, true).connect_to(chest_connector, false, defines.wire_origin.script)`.
  O uso de `defines.wire_origin.script` mantém os fios internos ocultos para o jogador.
- **Condição de circuito**:
  O formato da tabela `behavior.circuit_condition` foi simplificado e achatado:
  ```lua
  behavior.circuit_condition = {
    comparator = "=",
    first_signal = {type = "virtual", name = "railloader-disable"},
    constant = 0,
  }
  ```

### 3.4 Remoção da Entidade `flying-text`
No Factorio 2.0, a entidade de protótipo `flying-text` foi removida da engine.
- Ao posicionar o carregador fora da grade de trilho (grid 2x2), o mod chamava `show_error()`, gerando o crash `Unknown entity name: flying-text`.
- **Solução implementada:**
  - Uso de `player.create_local_flying_text{ text = ..., position = ... }` com animação nativa subindo na tela do jogador.
  - Fallback para `rendering.draw_text{ ... }` caso a ação tenha sido gerada por robôs/scripts sem jogador direto.
  - Atualizado em [control.lua](control.lua) e [inserterconfig.lua](inserterconfig.lua).

### 3.5 Adaptação para o Sistema de 16 Direções (`defines.direction`)

No Factorio 2.0, o enum `defines.direction` foi expandido de 8 para 16 direções (com `north = 0`, `east = 4`, `south = 8`, `west = 12`).

- **Problema encontrado:**
  - O código legado do Factorio 1.1 reduzia a direção do proxy com `if direction >= 4 then direction = direction - 4 end` assumindo 8 direções (onde `east = 2`, `south = 4`, `west = 6`).
  - No Factorio 2.0, ao colocar o carregador na horizontal (`direction = east = 4`), `direction` era subtraído para `0` (`north`).
  - Como consequência, ao colocar em trilhos horizontais:
    1. Os trilhos internos (`railloader-rail`) eram criados com direção vertical (`direction = 0`), ficando desconectados dos trilhos horizontais externos e quebrando o caminho dos trens / invalidando a estação.
    2. A estrutura colocada era `railloader-structure-vertical` em vez da horizontal.
    3. Os inserters internos recebiam orientações incorretas baseadas em módulo `% 8`.
- **Solução implementada:**
  - Em [control.lua](control.lua), verificação explícita de `is_horizontal = (direction == defines.direction.east or direction == defines.direction.west)`.
  - Trilhos internos colocados com `defines.direction.east` (horizontal) ou `defines.direction.north` (vertical).
  - Estrutura selecionada com base em `is_horizontal`.
  - Inserters internos rotacionados com base em 16 direções: `(base_direction + (i-1) * 8) % 16`.
  - Em [util.lua](util.lua), funções `opposite_direction` (`(dir + 8) % 16`), `orthogonal_direction` (`(dir + 4) % 16`) e `find_chests_from_railloader` adaptadas para o sistema de 16 direções.

---

## 4. Ambiente de Desenvolvimento e Validação

- **Link Simbólico (Junction):**
  Criado um diretório junction do Windows apontando de `%AppData%\Factorio\mods\railloader_2.1.0` diretamente para a pasta do código-fonte `C:\Users\claud\railloader_src`, permitindo alterações instantâneas sem necessidade de reempacotar `.zip`.
- **Testes Headless via CLI:**
  - `Factorio.exe --dump-data --disable-audio`: Validação completa da fase de protótipos.
  - `Factorio.exe --create test_map.zip --disable-audio`: Validação dos scripts e ciclo `on_init`.
- **Git e GitHub:**
  - Fork criado em: https://github.com/ClaudioASantana/factorio-railloader
  - Remote `fork` configurado localmente.
  - Branch de trabalho: `factorio-2.0` (o repositório original `mspielberg/factorio-railloader` foi preservado sem alterações).

---

## 5. Próximos Passos para os Testes

1. **Testar Posicionamento:**
   - Inserir o **descarregador** (`railunloader`) diretamente sobre um trilho reto (já validado com sucesso).
   - Inserir o **carregador** (`railloader`) diretamente alinhado com o trilho reto.
   - Testar colocar fora do grid para confirmar que o aviso vermelho *"Deve alinhar-se com a rede ferroviária"* aparece sem travar o jogo.
2. **Testar Operação com Trens:**
   - Estacionar um trem com vagão de carga na parada.
   - Verificar se os filtros dos inserters são configurados automaticamente com os itens válidos.
   - Enviar sinal de circuito `railloader-disable` (sinal virtual) no baú para verificar se a operação é pausada corretamente.
