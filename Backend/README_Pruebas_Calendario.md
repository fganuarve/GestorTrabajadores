# Pruebas Funcionales del Módulo Calendario

## 1. Listar Todos los Eventos
**Descripción:** Verificar `GET /api/eventos-calendario` devuelve todos los eventos.

**Precondiciones:**
- Backend en ejecución (localhost:8080).
- Al menos dos eventos en la BD.

**Entrada:**
```
GET http://localhost:8080/api/eventos-calendario
```

**Resultado Esperado:** HTTP 200 y array JSON con todos los campos (`id`, `titulo`, `descripcion`, `inicio`, `fin`, `diaCompleto`).

## 2. Crear Nuevo Evento
**Descripción:** Verificar `POST /api/eventos-calendario`.

**Entrada:**
```
POST http://localhost:8080/api/eventos-calendario
Content-Type: application/json

{
  "titulo": "Reunión Test",
  "descripcion": "Descripción de prueba",
  "inicio": "2025-05-01T10:00:00",
  "fin": "2025-05-01T11:00:00",
  "diaCompleto": false
}
```

**Resultado Esperado:** HTTP 200, JSON con `id` asignado. Al volver a listar, debe aparecer este evento.

## 3. Actualizar Evento Existente
**Descripción:** `PUT /api/eventos-calendario/{id}`.

**Entrada:**
```
PUT http://localhost:8080/api/eventos-calendario/1
Content-Type: application/json

{
  "titulo": "Reunión Actualizada",
  "descripcion": "Descripción modificada",
  "inicio": "2025-05-01T10:00:00",
  "fin": "2025-05-01T11:30:00",
  "diaCompleto": false
}
```

**Resultado Esperado:** HTTP 200. GET sobre /1 devuelve los nuevos valores.

## 4. Eliminar Evento
**Descripción:** `DELETE /api/eventos-calendario/{id}`.

**Entrada:**
```
DELETE http://localhost:8080/api/eventos-calendario/2
```

**Resultado Esperado:** HTTP 204. GET /2 → HTTP 404.

## 5. Casos Personalizados: Activos y Rango
**Activos:** Implementa en el controlador:
```java
@GetMapping("/activos")
public List<EventoDTO> activos() {
    return service.buscarActivos().stream()
                  .map(mapper::eventoToEventoDTO)
                  .collect(Collectors.toList());
}
```
**Prueba:**
```
GET http://localhost:8080/api/eventos-calendario/activos
```

**Rango:**
```java
@GetMapping("/rango")
public List<EventoDTO> rango(
    @RequestParam LocalDateTime desde,
    @RequestParam LocalDateTime hasta
) {
    return service.buscarPorRango(desde, hasta)
                  .stream()
                  .map(mapper::eventoToEventoDTO)
                  .collect(Collectors.toList());
}
```
**Prueba:**
```
GET http://localhost:8080/api/eventos-calendario/rango?desde=2025-05-01T00:00:00&hasta=2025-05-31T23:59:59
```

---
*Guarda este contenido en `README_Pruebas_Calendario.md` en la raíz del proyecto. Luego usa Postman o curl para ejecutar cada caso y comprobar los resultados.*

## 6. Pruebas Automatizadas con JUnit y Spring Boot Test

Para complementar las pruebas manuales, puedes escribir tests de integración que ejecuten la aplicación en un contexto de Spring y validen tus endpoints automáticamente.

1. Asegúrate de tener en tu `pom.xml` las dependencias:
```xml
<dependency>
  <groupId>org.springframework.boot</groupId>
  <artifactId>spring-boot-starter-test</artifactId>
  <scope>test</scope>
</dependency>
```

2. Crea el fichero de test:
`src/test/java/com/calendario/trabajadores/EventoCalendarioControllerTest.java`:
```java
package com.calendario.trabajadores;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.calendario.trabajadores.model.database.EventoCalendario;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import java.time.LocalDateTime;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
public class EventoCalendarioControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Test
    void pruebaCrearListarYEliminarEvento() throws Exception {
        // 1) Crear evento
        EventoCalendario e = new EventoCalendario();
        e.setTitulo("Test JUnit");
        e.setDescripcion("Prueba automática");
        e.setInicio(LocalDateTime.now().plusDays(1));
        e.setFin(LocalDateTime.now().plusDays(1).plusHours(1));
        e.setDiaCompleto(false);

        String jsonReq = objectMapper.writeValueAsString(e);
        String location = mockMvc.perform(post("/api/eventos-calendario")
                .contentType(MediaType.APPLICATION_JSON)
                .content(jsonReq))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.id").exists())
            .andReturn()
            .getResponse()
            .getContentAsString();

        // 2) Listar y verificar título
        mockMvc.perform(get("/api/eventos-calendario"))
               .andExpect(status().isOk())
               .andExpect(jsonPath("$[?(@.titulo=='Test JUnit')]").exists());

        // 3) Eliminar
        Long id = objectMapper.readTree(location).get("id").asLong();
        mockMvc.perform(delete("/api/eventos-calendario/" + id))
               .andExpect(status().isNoContent());
    }
}
```

3. Ejecuta los tests en tu terminal:
```bash
mvn test
```
Todos los métodos deberían pasar (green) comprobando tu API de calendario automáticamente.
