package com.calendario.trabajadores.mappings;

import com.calendario.trabajadores.model.database.Usuario;
import com.calendario.trabajadores.model.database.Vehiculo;
import com.calendario.trabajadores.model.dto.usuario.CrearUsuarioRequest;
import com.calendario.trabajadores.model.dto.usuario.EditarUsuarioRequest;
import com.calendario.trabajadores.model.dto.usuario.UsuarioResponse;
import com.calendario.trabajadores.model.dto.usuario.UsuarioVehiculosResponse;
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
public class IUserMapperImpl implements IUserMapper {

    @Override
    public UsuarioResponse userToCreateEditResponse(Usuario userDB) {
        if ( userDB == null ) {
            return null;
        }

        UsuarioResponse usuarioResponse = new UsuarioResponse();

        usuarioResponse.setCreadoPor( userDB.getCreadoPor() );
        usuarioResponse.setFechaCreacion( userDB.getFechaCreacion() );
        usuarioResponse.setFechaModificacion( userDB.getFechaModificacion() );
        usuarioResponse.setModificadoPor( userDB.getModificadoPor() );
        usuarioResponse.setActivo( userDB.getActivo() );
        usuarioResponse.setApellido1( userDB.getApellido1() );
        usuarioResponse.setApellido2( userDB.getApellido2() );
        usuarioResponse.setCentroTrabajo( userDB.getCentroTrabajo() );
        usuarioResponse.setDisponibilidadHorasExtras( userDB.getDisponibilidadHorasExtras() );
        usuarioResponse.setEmail( userDB.getEmail() );
        usuarioResponse.setId( userDB.getId() );
        usuarioResponse.setLocalidad( userDB.getLocalidad() );
        usuarioResponse.setNombre( userDB.getNombre() );
        usuarioResponse.setPreferenciasHorarias( userDB.getPreferenciasHorarias() );
        usuarioResponse.setPuesto( userDB.getPuesto() );
        usuarioResponse.setRol( userDB.getRol() );
        usuarioResponse.setTelefono( userDB.getTelefono() );

        return usuarioResponse;
    }

    @Override
    public Usuario createRequestToUser(CrearUsuarioRequest request) {
        if ( request == null ) {
            return null;
        }

        Usuario usuario = new Usuario();

        usuario.setContraseña( request.getPassword() );
        usuario.setActivo( request.getActivo() );
        usuario.setApellido1( request.getApellido1() );
        usuario.setApellido2( request.getApellido2() );
        usuario.setCentroTrabajo( request.getCentroTrabajo() );
        usuario.setDisponibilidadHorasExtras( request.getDisponibilidadHorasExtras() );
        usuario.setEmail( request.getEmail() );
        usuario.setLocalidad( request.getLocalidad() );
        usuario.setNombre( request.getNombre() );
        usuario.setPreferenciasHorarias( request.getPreferenciasHorarias() );
        usuario.setPuesto( request.getPuesto() );
        usuario.setRol( request.getRol() );
        usuario.setTelefono( request.getTelefono() );

        return usuario;
    }

    @Override
    public Usuario editRequestToUser(EditarUsuarioRequest request) {
        if ( request == null ) {
            return null;
        }

        Usuario usuario = new Usuario();

        usuario.setContraseña( request.getPassword() );
        usuario.setActivo( request.getActivo() );
        usuario.setApellido1( request.getApellido1() );
        usuario.setApellido2( request.getApellido2() );
        usuario.setCentroTrabajo( request.getCentroTrabajo() );
        usuario.setDisponibilidadHorasExtras( request.getDisponibilidadHorasExtras() );
        usuario.setEmail( request.getEmail() );
        usuario.setId( request.getId() );
        usuario.setLocalidad( request.getLocalidad() );
        usuario.setNombre( request.getNombre() );
        usuario.setPreferenciasHorarias( request.getPreferenciasHorarias() );
        usuario.setPuesto( request.getPuesto() );
        usuario.setRol( request.getRol() );
        usuario.setTelefono( request.getTelefono() );

        return usuario;
    }

    @Override
    public UsuarioVehiculosResponse usuarioToUsuarioVehiculosResponse(Usuario usuario) {
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

    @Override
    public UsuarioResponse usuarioToUsuarioResponse(Usuario usuario) {
        if ( usuario == null ) {
            return null;
        }

        UsuarioResponse usuarioResponse = new UsuarioResponse();

        usuarioResponse.setCreadoPor( usuario.getCreadoPor() );
        usuarioResponse.setFechaCreacion( usuario.getFechaCreacion() );
        usuarioResponse.setFechaModificacion( usuario.getFechaModificacion() );
        usuarioResponse.setModificadoPor( usuario.getModificadoPor() );
        usuarioResponse.setActivo( usuario.getActivo() );
        usuarioResponse.setApellido1( usuario.getApellido1() );
        usuarioResponse.setApellido2( usuario.getApellido2() );
        usuarioResponse.setCentroTrabajo( usuario.getCentroTrabajo() );
        usuarioResponse.setDisponibilidadHorasExtras( usuario.getDisponibilidadHorasExtras() );
        usuarioResponse.setEmail( usuario.getEmail() );
        usuarioResponse.setId( usuario.getId() );
        usuarioResponse.setLocalidad( usuario.getLocalidad() );
        usuarioResponse.setNombre( usuario.getNombre() );
        usuarioResponse.setPreferenciasHorarias( usuario.getPreferenciasHorarias() );
        usuarioResponse.setPuesto( usuario.getPuesto() );
        usuarioResponse.setRol( usuario.getRol() );
        usuarioResponse.setTelefono( usuario.getTelefono() );

        return usuarioResponse;
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
}
