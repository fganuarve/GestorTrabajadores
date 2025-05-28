package com.calendario.trabajadores.services.turno;

import com.calendario.trabajadores.model.database.Turno;
import com.calendario.trabajadores.model.dto.turno.TurnoResponse;
import com.calendario.trabajadores.model.errorresponse.ErrorResponse;
import com.calendario.trabajadores.model.errorresponse.GenericResponse;
import com.calendario.trabajadores.repository.TurnoRepository;
import com.calendario.trabajadores.services.user.UserService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.time.ZoneId;
import java.util.Date;
import java.util.List;
import java.util.stream.Collectors;

@Service
public class TurnoService {

    @Autowired
    private TurnoRepository turnoRepository;
    
    @Autowired
    private UserService userService;

    public GenericResponse<List<TurnoResponse>> getShiftsByUserAndDateRange(Long userId, LocalDate startDate, LocalDate endDate) {
        // Verificar si el usuario existe
        var userResponse = userService.getUsuario(userId);
        if (!userResponse.isSuccess()) {
            return new GenericResponse<>(new ErrorResponse("USER_NOT_FOUND", "Usuario no encontrado", HttpStatus.NOT_FOUND.value()));
        }

        try {
            // Convertir LocalDate a Date
            Date start = Date.from(startDate.atStartOfDay(ZoneId.systemDefault()).toInstant());
            // Añadir un día a la fecha de fin para incluir todo el último día
            Date end = Date.from(endDate.plusDays(1).atStartOfDay(ZoneId.systemDefault()).toInstant());

            // Obtener los turnos del usuario en el rango de fechas
            List<Turno> turnos = turnoRepository.findByUsuarioIdAndHoraInicioBetween(
                    userId, start, end);

            // Filtrar solo los turnos activos
            List<Turno> turnosActivos = turnos.stream()
                    .filter(turno -> turno.getActivo() != null && turno.getActivo())
                    .collect(Collectors.toList());

            // Mapear a DTO
            List<TurnoResponse> response = turnosActivos.stream()
                    .map(this::mapToTurnoResponse)
                    .collect(Collectors.toList());

            return new GenericResponse<>(response);
        } catch (Exception e) {
            return new GenericResponse<>(new ErrorResponse("INTERNAL_ERROR", "Error al obtener los turnos: " + e.getMessage(), 
                HttpStatus.INTERNAL_SERVER_ERROR.value()));
        }
    }


    private TurnoResponse mapToTurnoResponse(Turno turno) {
        TurnoResponse response = new TurnoResponse();
        response.setId(turno.getId());
        response.setUsuarioId(turno.getUsuario().getId());
        response.setTipoTurno(determinarTipoTurno(turno.getHoraInicio(), turno.getHoraFin()));
        response.setFechaHoraInicio(convertToLocalDateTime(turno.getHoraInicio()));
        response.setFechaHoraFin(convertToLocalDateTime(turno.getHoraFin()));
        response.setNotas(turno.getNotasPeticion());
        return response;
    }

    private String determinarTipoTurno(Date horaInicio, Date horaFin) {
        // Lógica para determinar el tipo de turno basado en las horas
        // Esta es una implementación de ejemplo, ajústala según tus necesidades
        long diffInHours = (horaFin.getTime() - horaInicio.getTime()) / (60 * 60 * 1000);
        
        if (diffInHours <= 8) {
            return "MORNING";
        } else if (diffInHours <= 16) {
            return "AFTERNOON";
        } else {
            return "NIGHT";
        }
    }

    private java.time.LocalDateTime convertToLocalDateTime(Date dateToConvert) {
        return dateToConvert.toInstant()
                .atZone(ZoneId.systemDefault())
                .toLocalDateTime();
    }
}
