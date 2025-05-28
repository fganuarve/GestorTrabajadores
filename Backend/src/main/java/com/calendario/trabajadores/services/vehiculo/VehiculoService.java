package com.calendario.trabajadores.services.vehiculo;

import com.calendario.trabajadores.mappings.IVehiculoMapper;
import com.calendario.trabajadores.model.database.Usuario;
import com.calendario.trabajadores.model.database.Vehiculo;
import com.calendario.trabajadores.model.dto.vehiculo.CrearEditarVehiculoResponse;
import com.calendario.trabajadores.model.dto.vehiculo.CrearVehiculoRequest;
import com.calendario.trabajadores.model.dto.vehiculo.EditarVehiculoRequest;
import com.calendario.trabajadores.model.errorresponse.ErrorResponse;
import com.calendario.trabajadores.model.errorresponse.GenericResponse;
import com.calendario.trabajadores.repository.vehiculo.IVehiculoRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

@Service
public class VehiculoService {
    //Inyeccion de dependencias
    private final IVehiculoRepository vehiculoRepository;
    private final IVehiculoMapper vehiculoMapper;

    //Constructor de VehiculoService

    public VehiculoService(IVehiculoRepository vehiculoRepository, IVehiculoMapper vehiculoMapper) {

        this.vehiculoRepository = vehiculoRepository;
        this.vehiculoMapper = vehiculoMapper;
    }

    //Crear un vehiculo
    public GenericResponse<CrearEditarVehiculoResponse> crearVehiculo(CrearVehiculoRequest request) {
        GenericResponse<CrearEditarVehiculoResponse> responseWrapper = new GenericResponse<>();

        // Busco el vehículo por matrícula para saber si ya existe
        var vehiculoExists = vehiculoRepository.findVehiculoByMatricula(request.matricula);

        // Si existe, devolvemos un error
        if (vehiculoExists.isPresent()) {
            responseWrapper.setError(new ErrorResponse("El vehículo ya existe"));
            return responseWrapper;
        }

        // Si no existe, creamos el vehículo
        Vehiculo vehiculoModel = vehiculoMapper.createRequestToVehiculo(request);

        // Guardamos en la base de datos
        Vehiculo v_guardado = vehiculoRepository.save(vehiculoModel);

        // Mapeamos la respuesta
        var response = vehiculoMapper.vehiculoToCreateEditResponse(v_guardado);

        // Devolvemos la respuesta exitosa
        responseWrapper.setData(response);
        return responseWrapper;
    }

    //Metodo para modificar un vehiculo
    public GenericResponse<CrearEditarVehiculoResponse> modificarVehiculo(EditarVehiculoRequest request) {
        GenericResponse<CrearEditarVehiculoResponse> responseWrapper = new GenericResponse<>();

        // Buscar el vehículo por ID
        Optional<Vehiculo> vehiculoOptional = vehiculoRepository.findById(request.id);

        if (vehiculoOptional.isEmpty()) {
            responseWrapper.setError(new ErrorResponse("El vehículo no existe"));
            return responseWrapper;
        }

        Vehiculo vehiculoModel = vehiculoOptional.get();

        // Actualizar solo los campos que se envían en la petición
        if (!request.getMatricula().isBlank()) {
            vehiculoModel.setMatricula(request.getMatricula());
        }
        if (!request.getModeloCoche().isBlank()) {
            vehiculoModel.setModeloCoche(request.getModeloCoche());
        }
        if (request.getActivo() != null) {
            vehiculoModel.setActivo(request.getActivo());
        }
        if (request.getPlazas() != 0) {
            vehiculoModel.setPlazas(request.getPlazas());
        }

        // Si se proporciona un ID de usuario, se asocia el vehículo al usuario correspondiente
        if (request.getIdUsuario() != 0) {
            Usuario tempUser = new Usuario();
            tempUser.setId(request.getIdUsuario());
            vehiculoModel.setUsuario(tempUser);
        }

        // Guardar los cambios en la base de datos
        Vehiculo v_actualizado = vehiculoRepository.save(vehiculoModel);

        // Mapear la respuesta y devolverla con éxito
        responseWrapper.setData(vehiculoMapper.vehiculoToCreateEditResponse(v_actualizado));
        return responseWrapper;
    }


    //Metodo para desactivar un vehiculo (activo = false)
    public GenericResponse<CrearEditarVehiculoResponse> toggleVehiculo(Long id) {
        GenericResponse<CrearEditarVehiculoResponse> responseWrapper = new GenericResponse<>();

        // Buscar el vehículo por ID
        Optional<Vehiculo> vehiculoOpt = vehiculoRepository.findById(id);

        // Si no existe, devolver error
        if (vehiculoOpt.isEmpty()) {
            responseWrapper.setError(new ErrorResponse("El vehículo no existe"));
            return responseWrapper;
        }

        // Cambiar el estado del vehículo
        Vehiculo tempV = vehiculoOpt.get();
        tempV.setActivo(!tempV.getActivo());

        // Guardar cambios en la base de datos
        Vehiculo v_actualizado = vehiculoRepository.save(tempV);

        // Mapear a DTO y devolver respuesta exitosa
        responseWrapper.setData(vehiculoMapper.vehiculoToCreateEditResponse(v_actualizado));
        return responseWrapper;
    }


    //Metodo para listar todos los vehiculos de un usuario (Las tres opciones null, activo =true y activo=false) TODO
    public GenericResponse<List<CrearEditarVehiculoResponse>> listarVehiculos(Long usuarioId, Optional<Boolean> activo) {
        GenericResponse<List<CrearEditarVehiculoResponse>> responseWrapper = new GenericResponse<>();

        // Llamar al repositorio para obtener los vehículos filtrados según el estado
        List<Vehiculo> vehiculos = vehiculoRepository.listarVehiculosUsuarioConFiltro(usuarioId, activo);

        // Si no hay vehículos, devolver un mensaje adecuado
        if (vehiculos.isEmpty()) {
            responseWrapper.setError(new ErrorResponse("No se encontraron vehículos"));
            return responseWrapper;
        }

        // Convertir la lista de vehículos a DTOs
        List<CrearEditarVehiculoResponse> listaDTO = vehiculos.stream()
                .map(vehiculo -> vehiculoMapper.vehiculoToCreateEditResponse(vehiculo))
                .toList();

        // Devolver la lista de vehículos en la respuesta exitosa
        responseWrapper.setData(listaDTO);
        return responseWrapper;
    }

    public GenericResponse<String> eliminarVehiculo(Long id) {
        // TODO Auto-generated method stub
        throw new UnsupportedOperationException("Unimplemented method 'eliminarVehiculo'");
    }

    public GenericResponse<CrearEditarVehiculoResponse> obtenerVehiculoPorMatricula(String matricula) {
        // TODO Auto-generated method stub
        throw new UnsupportedOperationException("Unimplemented method 'obtenerVehiculoPorMatricula'");
    }

    public GenericResponse<CrearEditarVehiculoResponse> obtenerVehiculoPorId(Long id) {
        // TODO Auto-generated method stub
        throw new UnsupportedOperationException("Unimplemented method 'obtenerVehiculoPorId'");
    }



}

