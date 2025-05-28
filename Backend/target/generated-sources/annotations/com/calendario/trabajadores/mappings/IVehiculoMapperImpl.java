package com.calendario.trabajadores.mappings;

import com.calendario.trabajadores.model.database.Usuario;
import com.calendario.trabajadores.model.database.Vehiculo;
import com.calendario.trabajadores.model.dto.usuario.UsuarioVehiculosResponse;
import com.calendario.trabajadores.model.dto.vehiculo.CrearEditarVehiculoResponse;
import com.calendario.trabajadores.model.dto.vehiculo.CrearVehiculoRequest;
import com.calendario.trabajadores.model.dto.vehiculo.EditarVehiculoRequest;
import com.calendario.trabajadores.model.dto.vehiculo.VehiculoDTO;
import java.util.ArrayList;
import java.util.List;
import javax.annotation.processing.Generated;
import org.springframework.stereotype.Component;

@Generated(
    value = "org.mapstruct.ap.MappingProcessor",
    date = "2025-05-28T23:48:43+0200",
    comments = "version: 1.6.3, compiler: Eclipse JDT (IDE) 3.42.0.v20250514-1000, environment: Java 21.0.7 (Eclipse Adoptium)"
)
@Component
public class IVehiculoMapperImpl implements IVehiculoMapper {

    @Override
    public CrearEditarVehiculoResponse vehiculoToCreateEditResponse(Vehiculo vehiculoDB) {
        if ( vehiculoDB == null ) {
            return null;
        }

        CrearEditarVehiculoResponse crearEditarVehiculoResponse = new CrearEditarVehiculoResponse();

        crearEditarVehiculoResponse.setActivo( vehiculoDB.getActivo() );
        crearEditarVehiculoResponse.setFechaCreacion( vehiculoDB.getFechaCreacion() );
        crearEditarVehiculoResponse.setFechaModificacion( vehiculoDB.getFechaModificacion() );
        crearEditarVehiculoResponse.setId( vehiculoDB.getId() );
        crearEditarVehiculoResponse.setMatricula( vehiculoDB.getMatricula() );
        crearEditarVehiculoResponse.setModeloCoche( vehiculoDB.getModeloCoche() );
        crearEditarVehiculoResponse.setPlazas( vehiculoDB.getPlazas() );
        crearEditarVehiculoResponse.setUsuario( usuarioToUsuarioVehiculosResponse( vehiculoDB.getUsuario() ) );

        return crearEditarVehiculoResponse;
    }

    @Override
    public Vehiculo createRequestToVehiculo(CrearVehiculoRequest request) {
        if ( request == null ) {
            return null;
        }

        Vehiculo vehiculo = new Vehiculo();

        vehiculo.setUsuario( crearVehiculoRequestToUsuario( request ) );
        vehiculo.setActivo( request.getActivo() );
        vehiculo.setMatricula( request.getMatricula() );
        vehiculo.setModeloCoche( request.getModeloCoche() );
        if ( request.getPlazas() != null ) {
            vehiculo.setPlazas( request.getPlazas() );
        }

        return vehiculo;
    }

    @Override
    public Vehiculo editRequestToUser(EditarVehiculoRequest request) {
        if ( request == null ) {
            return null;
        }

        Vehiculo vehiculo = new Vehiculo();

        vehiculo.setUsuario( editarVehiculoRequestToUsuario( request ) );
        vehiculo.setActivo( request.getActivo() );
        vehiculo.setId( request.getId() );
        vehiculo.setMatricula( request.getMatricula() );
        vehiculo.setModeloCoche( request.getModeloCoche() );
        if ( request.getPlazas() != null ) {
            vehiculo.setPlazas( request.getPlazas() );
        }

        return vehiculo;
    }

    protected VehiculoDTO vehiculoToVehiculoDTO(Vehiculo vehiculo) {
        if ( vehiculo == null ) {
            return null;
        }

        VehiculoDTO vehiculoDTO = new VehiculoDTO();

        vehiculoDTO.setCreadoPor( vehiculo.getCreadoPor() );
        vehiculoDTO.setFechaCreacion( vehiculo.getFechaCreacion() );
        vehiculoDTO.setFechaModificacion( vehiculo.getFechaModificacion() );
        vehiculoDTO.setModificadoPor( vehiculo.getModificadoPor() );
        vehiculoDTO.setActivo( vehiculo.getActivo() );
        vehiculoDTO.setId( vehiculo.getId() );
        vehiculoDTO.setMatricula( vehiculo.getMatricula() );
        vehiculoDTO.setModeloCoche( vehiculo.getModeloCoche() );
        vehiculoDTO.setPlazas( vehiculo.getPlazas() );

        return vehiculoDTO;
    }

    protected List<VehiculoDTO> vehiculoListToVehiculoDTOList(List<Vehiculo> list) {
        if ( list == null ) {
            return null;
        }

        List<VehiculoDTO> list1 = new ArrayList<VehiculoDTO>( list.size() );
        for ( Vehiculo vehiculo : list ) {
            list1.add( vehiculoToVehiculoDTO( vehiculo ) );
        }

        return list1;
    }

    protected UsuarioVehiculosResponse usuarioToUsuarioVehiculosResponse(Usuario usuario) {
        if ( usuario == null ) {
            return null;
        }

        UsuarioVehiculosResponse usuarioVehiculosResponse = new UsuarioVehiculosResponse();

        usuarioVehiculosResponse.setActivo( usuario.getActivo() );
        usuarioVehiculosResponse.setApellido1( usuario.getApellido1() );
        usuarioVehiculosResponse.setApellido2( usuario.getApellido2() );
        usuarioVehiculosResponse.setEmail( usuario.getEmail() );
        usuarioVehiculosResponse.setId( usuario.getId() );
        usuarioVehiculosResponse.setNombre( usuario.getNombre() );
        usuarioVehiculosResponse.setVehiculos( vehiculoListToVehiculoDTOList( usuario.getVehiculos() ) );

        return usuarioVehiculosResponse;
    }

    protected Usuario crearVehiculoRequestToUsuario(CrearVehiculoRequest crearVehiculoRequest) {
        if ( crearVehiculoRequest == null ) {
            return null;
        }

        Usuario usuario = new Usuario();

        usuario.setId( crearVehiculoRequest.getIdUsuario() );

        return usuario;
    }

    protected Usuario editarVehiculoRequestToUsuario(EditarVehiculoRequest editarVehiculoRequest) {
        if ( editarVehiculoRequest == null ) {
            return null;
        }

        Usuario usuario = new Usuario();

        usuario.setId( editarVehiculoRequest.getIdUsuario() );

        return usuario;
    }
}
