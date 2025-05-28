package com.calendario.trabajadores.model.errorresponse;


import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter

/*
 * Clase genérica para manejar las respuestas de la API.
 * Permite devolver datos en caso de éxito o error.
 *
 * @param <T> El tipo de dato de la respuesta será cualquier clase
 */
@Schema(description = "Generic response model")
public class GenericResponse<T> {

    /**
     * Datos de la respuesta si la operación es exitosa.
     */
    @Schema(description = "Data returned in response")
    private T data;

    /**
     * Información del error si la operación falla.
     */
    @Schema(description = "Error details, if any")
    private ErrorResponse error;

    /**
     * Constructor vacío.
     */
    public GenericResponse() {
    }
    
    /**
     * Constructor con datos de respuesta.
     * @param data Los datos de la respuesta exitosa
     */
    public GenericResponse(T data) {
        this.data = data;
        this.error = null;
    }
    
    /**
     * Constructor con error.
     * @param error Los detalles del error
     */
    public GenericResponse(ErrorResponse error) {
        this.data = null;
        this.error = error;
    }
    
    /**
     * Constructor con datos y error.
     * @param data Los datos de la respuesta
     * @param error Los detalles del error (puede ser null)
     */
    public GenericResponse(T data, ErrorResponse error) {
        this.data = data;
        this.error = error;
    }


    /**
     * Verifica si la respuesta es exitosa (sin errores).
     *
     * @return {@code true} si no hay error, {@code false} si hay un error.
     */
    public boolean isSuccess() {
        return error == null;
    }

}
