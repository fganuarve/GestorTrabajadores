package com.calendario.trabajadores.controllers;

import com.calendario.trabajadores.model.errorresponse.ErrorResponse;
import com.calendario.trabajadores.model.errorresponse.GenericResponse;
import com.calendario.trabajadores.services.turno.TurnoService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.Map;

@RestController
@RequestMapping("/api")
@Tag(name = "Turno", description = "Endpoints para la gestión de turnos")
public class TurnoController {
    
    @Autowired
    private TurnoService turnoService;

    @Operation(summary = "Obtener turnos por usuario y rango de fechas", 
              description = "Endpoint para obtener los turnos de un usuario en un rango de fechas específico")
    @GetMapping("/shifts/user/{userId}")
    @ApiResponses(value = {
        @ApiResponse(responseCode = "200", description = "Turnos encontrados"),
        @ApiResponse(responseCode = "400", description = "Bad Request",
                   content = @Content(schema = @Schema(implementation = ErrorResponse.class))),
        @ApiResponse(responseCode = "404", description = "Usuario no encontrado",
                   content = @Content(schema = @Schema(implementation = ErrorResponse.class)))
    })
    public ResponseEntity<?> getShiftsByUserAndDateRange(
            @PathVariable Long userId,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate) {
        
        if (startDate.isAfter(endDate)) {
            return ResponseEntity.badRequest()
                    .body(Map.of("error", "La fecha de inicio no puede ser posterior a la fecha de fin"));
        }

        try {
            var response = turnoService.getShiftsByUserAndDateRange(userId, startDate, endDate);
            
            if (!response.isSuccess()) {
                if (response.getError().getStatus().equals("USER_NOT_FOUND")) {
                    return ResponseEntity.status(HttpStatus.NOT_FOUND)
                            .body(Map.of("error", response.getError().getMessage()));
                }
                return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                        .body(Map.of("error", response.getError().getMessage()));
            }

            return ResponseEntity.ok(response.getData());
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("error", "Error interno del servidor al procesar la solicitud"));
        }
    }
}