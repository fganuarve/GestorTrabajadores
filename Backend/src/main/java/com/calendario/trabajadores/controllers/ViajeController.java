package com.calendario.trabajadores.controllers;

import com.calendario.trabajadores.model.dto.viaje.CrearEditarViajeResponse;
import com.calendario.trabajadores.model.dto.viaje.CrearViajeRequest;
import com.calendario.trabajadores.model.dto.viaje.EditarViajeRequest;
import com.calendario.trabajadores.model.dto.viaje.ViajeResponse;
import com.calendario.trabajadores.model.errorresponse.ErrorResponse;
import com.calendario.trabajadores.model.errorresponse.GenericResponse;
import com.calendario.trabajadores.services.user.UserService;
import com.calendario.trabajadores.services.viaje.ViajeService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.ArraySchema;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;





@RestController
@Tag(name = "Viajes", description = "Endpoints para viajes")
public class ViajeController {
    //Inyeccion de dependencias
    @Autowired
    private ViajeService viajeService;
    @Autowired
    private UserService userService;

    //No necesito el constructor porque ya tengo la inyeccion de dependencias con @Autowired ***********
    public ViajeController(ViajeService viajeService, UserService userService) {
        this.viajeService = viajeService;
        this.userService = userService;
    }

    //Crear un nuevo viaje        *F*
    @Operation(summary = "Creación de viaje", description = "Endpoint para crear un viaje")
    @PostMapping("/viaje/crear")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Viaje creado",
                    content = @Content(mediaType = "application/json", schema = @Schema(implementation = CrearEditarViajeResponse.class))),
            @ApiResponse(responseCode = "400", description = "Bad Request",
                    content = @Content(mediaType = "application/json", schema = @Schema(implementation = ErrorResponse.class)))}
    )
    public ResponseEntity<?> crearViaje(@RequestBody CrearViajeRequest input) {
        // Llamamos al servicio para crear el viaje
        GenericResponse<CrearEditarViajeResponse> viajeResponse = viajeService.crearViaje(input);

        // Si hay un error en la respuesta
        if (viajeResponse.getError() != null) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(viajeResponse.getError());
        }

        // Si la creación fue exitosa, devolvemos la respuesta con los datos del viaje creado
        return ResponseEntity.ok(viajeResponse.getData());
    }



    /*@Operation(summary = "Crear un viaje", description = "Endpoint crear viaje")
    @PostMapping("/viaje/crear")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Viaje creado",
                    content = @Content(mediaType = "application/json", schema = @Schema(implementation = CrearEditarViajeResponse.class))),
            @ApiResponse(responseCode = "400", description = "Bad Request",
                    content = @Content(mediaType = "application/json", schema = @Schema(implementation = ErrorResponse.class)))
    }
    )
    public ResponseEntity<?> crearViaje(@RequestBody CrearViajeRequest input) {
        // Llamamos al servicio para crear el viaje
        GenericResponse<CrearEditarViajeResponse> viajeResponse = viajeService.crearViaje(input);

        // Si no se pudo crear el viaje, devolvemos BAD_REQUEST con el error adecuado
        if (!viajeResponse.isSuccess()) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(Map.of(viajeResponse.getError().getStatus(), viajeResponse.getError().getMessage()));
        }

        // Si el viaje se creó correctamente, devolvemos la respuesta con los datos del viaje creado
        return ResponseEntity.ok(viajeResponse);
    }*/


    // Cambiar estado de un viaje  TODO:toggle
    @Operation(summary = "Cambiar estado de un viaje", description = "Endpoint para cambiar el estado de un viaje")
    @PatchMapping("/viaje/estado")   //PATCH para actualizar solo el estado NO POST NI GET
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Estado del viaje cambiado",
                    content = @Content(mediaType = "application/json", schema = @Schema(implementation = CrearEditarViajeResponse.class))),
            @ApiResponse(responseCode = "400", description = "Bad Request",
                    content = @Content(mediaType = "application/json", schema = @Schema(implementation = ErrorResponse.class))),
            @ApiResponse(responseCode = "404", description = "Viaje no encontrado",
                    content = @Content(mediaType = "application/json", schema = @Schema(implementation = ErrorResponse.class)))
    })
    public ResponseEntity<?> cambiarEstadoViaje(
            @PathVariable Long idViaje,
            @RequestParam String action  // Ahora esperamos un String "action" en lugar de "nuevoEstado"
    ) {
        // Llamamos al servicio para cambiar el estado del viaje
        GenericResponse<CrearEditarViajeResponse> viajeResponse = viajeService.cambiarEstadoViaje(idViaje, action);

        // Si hay un error en la respuesta
        if (viajeResponse.getError() != null) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(viajeResponse.getError());
        }

        // Si todo va bien, retornamos el viaje actualizado
        return ResponseEntity.ok(viajeResponse.getData());
    }


    //Editar datos de un viaje (no revisado) TODO:añadir validacion de no se peude editar un viaje en curso o finalizado.
    //(la mayoria de los datos del viaje son editables mientras no tenga pasajero asignado!)**
    //este endpoint deberia ser solo para viajes sin pasajero asignado !!!**L
    @Operation(summary = "Editar datos de un viaje", description = "Endpoint para editar datos de un viaje")
    @PatchMapping("/viaje/editarDatos/{idViaje}")  // Usamos PATCH porque es para editar
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Datos del viaje modificados",
                    content = @Content(mediaType = "application/json", schema = @Schema(implementation = CrearEditarViajeResponse.class))),
            @ApiResponse(responseCode = "400", description = "Bad Request",
                    content = @Content(mediaType = "application/json", schema = @Schema(implementation = ErrorResponse.class))),
            @ApiResponse(responseCode = "404", description = "Viaje no encontrado o no editable",
                    content = @Content(mediaType = "application/json", schema = @Schema(implementation = ErrorResponse.class)))
    })
    public ResponseEntity<?> editarViaje(
            @PathVariable Long idViaje,
            @RequestBody EditarViajeRequest model
    ) {
        // Llamamos al servicio para editar el viaje
        GenericResponse<CrearEditarViajeResponse> viajeResponse = viajeService.editarViaje(idViaje, model);

        // Si hay un error en la respuesta
        if (viajeResponse.getError() != null) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(viajeResponse.getError());
        }

        // Si la edición fue exitosa, devolvemos la respuesta con el viaje editado
        return ResponseEntity.ok(viajeResponse.getData());
    }

    //Endpoint de prueba
    @Operation(summary = "Devolver toda la informacion de un viaje", description = "Endpoint para listar toda la informacion de un viaje")
    @GetMapping("/viaje/listar")  // Usamos PATCH porque es para editar
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Datos del viaje listados",
                    content = @Content(mediaType = "application/json", schema = @Schema(implementation = ViajeResponse.class))),
            @ApiResponse(responseCode = "400", description = "Bad Request",
                    content = @Content(mediaType = "application/json", schema = @Schema(implementation = ErrorResponse.class))),
            @ApiResponse(responseCode = "404", description = "Viaje no encontrado",
                    content = @Content(mediaType = "application/json", schema = @Schema(implementation = ErrorResponse.class)))
    })
    public ResponseEntity<?> usuariosViaje(
            @RequestParam Long idViaje// Aquí utilizamos PathVariable para pasar el ID en la URL

    ) {
        // Llamamos al servicio para editar el viaje, pasamos el id y el EditarViajeRequest
        var viajeDatos = viajeService.listarDatosViaje(idViaje);

        // Verificamos si el viaje fue encontrado y editado correctamente
        if (viajeDatos.isEmpty()) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(new ErrorResponse("Viaje no encontrado"));
        }

        // Si la edición fue exitosa, devolvemos la respuesta con el viaje editado
        return ResponseEntity.ok(viajeDatos.get());
    }



    // Listar todos los viajes disponibles
    @Operation(summary = "Listar viajes disponibles", description = "Endpoint para listar los viajes disponibles")
    @GetMapping("/viaje/disponibles")
    @ApiResponses({
        @ApiResponse(responseCode = "200", description = "Lista de viajes disponibles obtenida",
            content = @Content(mediaType = "application/json", 
                array = @ArraySchema(schema = @Schema(implementation = CrearEditarViajeResponse.class)))),
        @ApiResponse(responseCode = "400", description = "Bad Request",
            content = @Content(mediaType = "application/json", 
                schema = @Schema(implementation = ErrorResponse.class))),
        @ApiResponse(responseCode = "404", description = "No se encontraron viajes disponibles",
            content = @Content(mediaType = "application/json", 
                schema = @Schema(implementation = ErrorResponse.class)))
    })
    public ResponseEntity<?> listarViajesDisponibles(
            @RequestParam(required = false) String fecha,  // Fecha opcional para filtrar
            @RequestParam(required = false) String origen,  // Origen opcional para filtrar
            @RequestParam(required = false) String destino  // Destino opcional para filtrar
    ) {
        // Llamamos al servicio para listar los viajes disponibles
        List<CrearEditarViajeResponse> viajesResponse = viajeService.listarViajesDisponibles(fecha, origen, destino);

        // Verificamos si la lista está vacía
        if (viajesResponse.isEmpty()) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(new ErrorResponse("No se encontraron viajes disponibles"));
        }

        // Si la lista no está vacía, retornamos la lista de viajes
        return ResponseEntity.ok(viajesResponse);
    }
}