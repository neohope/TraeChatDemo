package response

import (
	"encoding/json"
	"fmt"
	"net/http"
	"time"
)

// Response 统一响应结构
type Response struct {
	Success   bool        `json:"success"`
	Message   string      `json:"message,omitempty"`
	Data      interface{} `json:"data,omitempty"`
	Error     *ErrorInfo  `json:"error,omitempty"`
	Timestamp time.Time   `json:"timestamp"`
	RequestID string      `json:"request_id,omitempty"`
}

// ErrorInfo 错误信息
type ErrorInfo struct {
	Code    string      `json:"code"`
	Message string      `json:"message"`
	Details interface{} `json:"details,omitempty"`
}

// PaginationInfo 分页信息
type PaginationInfo struct {
	Total  int `json:"total"`
	Limit  int `json:"limit"`
	Offset int `json:"offset"`
	Pages  int `json:"pages"`
}

// PaginatedResponse 分页响应
type PaginatedResponse struct {
	Data       interface{}     `json:"data"`
	Pagination PaginationInfo  `json:"pagination"`
}

// Success 成功响应
func Success(w http.ResponseWriter, data interface{}) {
	SuccessWithMessage(w, "", data)
}

// SuccessWithMessage 带消息的成功响应
func SuccessWithMessage(w http.ResponseWriter, message string, data interface{}) {
	response := Response{
		Success:   true,
		Message:   message,
		Data:      data,
		Timestamp: time.Now(),
	}

	writeJSON(w, http.StatusOK, response)
}

// Error 错误响应
func Error(w http.ResponseWriter, statusCode int, message string, details interface{}) {
	ErrorWithCode(w, statusCode, getErrorCode(statusCode), message, details)
}

// ErrorWithCode 带错误码的错误响应
func ErrorWithCode(w http.ResponseWriter, statusCode int, code, message string, details interface{}) {
	response := Response{
		Success: false,
		Error: &ErrorInfo{
			Code:    code,
			Message: message,
			Details: details,
		},
		Timestamp: time.Now(),
	}

	writeJSON(w, statusCode, response)
}

// Paginated 分页响应
func Paginated(w http.ResponseWriter, data interface{}, total, limit, offset int) {
	pages := (total + limit - 1) / limit // 向上取整
	if pages < 1 {
		pages = 1
	}

	paginatedData := PaginatedResponse{
		Data: data,
		Pagination: PaginationInfo{
			Total:  total,
			Limit:  limit,
			Offset: offset,
			Pages:  pages,
		},
	}

	Success(w, paginatedData)
}

// Created 创建成功响应
func Created(w http.ResponseWriter, data interface{}) {
	response := Response{
		Success:   true,
		Message:   "Resource created successfully",
		Data:      data,
		Timestamp: time.Now(),
	}

	writeJSON(w, http.StatusCreated, response)
}

// Updated 更新成功响应
func Updated(w http.ResponseWriter, data interface{}) {
	response := Response{
		Success:   true,
		Message:   "Resource updated successfully",
		Data:      data,
		Timestamp: time.Now(),
	}

	writeJSON(w, http.StatusOK, response)
}

// Deleted 删除成功响应
func Deleted(w http.ResponseWriter) {
	response := Response{
		Success:   true,
		Message:   "Resource deleted successfully",
		Timestamp: time.Now(),
	}

	writeJSON(w, http.StatusOK, response)
}

// NoContent 无内容响应
func NoContent(w http.ResponseWriter) {
	w.WriteHeader(http.StatusNoContent)
}

// BadRequest 400错误响应
func BadRequest(w http.ResponseWriter, message string, details interface{}) {
	Error(w, http.StatusBadRequest, message, details)
}

// Unauthorized 401错误响应
func Unauthorized(w http.ResponseWriter, message string) {
	if message == "" {
		message = "Unauthorized access"
	}
	Error(w, http.StatusUnauthorized, message, nil)
}

// Forbidden 403错误响应
func Forbidden(w http.ResponseWriter, message string) {
	if message == "" {
		message = "Access forbidden"
	}
	Error(w, http.StatusForbidden, message, nil)
}

// NotFound 404错误响应
func NotFound(w http.ResponseWriter, message string) {
	if message == "" {
		message = "Resource not found"
	}
	Error(w, http.StatusNotFound, message, nil)
}

// Conflict 409错误响应
func Conflict(w http.ResponseWriter, message string, details interface{}) {
	Error(w, http.StatusConflict, message, details)
}

// UnprocessableEntity 422错误响应
func UnprocessableEntity(w http.ResponseWriter, message string, details interface{}) {
	Error(w, http.StatusUnprocessableEntity, message, details)
}

// TooManyRequests 429错误响应
func TooManyRequests(w http.ResponseWriter, message string) {
	if message == "" {
		message = "Too many requests"
	}
	Error(w, http.StatusTooManyRequests, message, nil)
}

// InternalServerError 500错误响应
func InternalServerError(w http.ResponseWriter, message string) {
	if message == "" {
		message = "Internal server error"
	}
	Error(w, http.StatusInternalServerError, message, nil)
}

// ServiceUnavailable 503错误响应
func ServiceUnavailable(w http.ResponseWriter, message string) {
	if message == "" {
		message = "Service unavailable"
	}
	Error(w, http.StatusServiceUnavailable, message, nil)
}

// ValidationError 验证错误响应
func ValidationError(w http.ResponseWriter, errors map[string]string) {
	ErrorWithCode(w, http.StatusBadRequest, "VALIDATION_ERROR", "Validation failed", errors)
}

// writeJSON 写入JSON响应
func writeJSON(w http.ResponseWriter, statusCode int, data interface{}) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(statusCode)

	if err := json.NewEncoder(w).Encode(data); err != nil {
		// 如果JSON编码失败，写入简单的错误响应
		w.WriteHeader(http.StatusInternalServerError)
		w.Write([]byte(`{"success":false,"error":{"code":"JSON_ENCODE_ERROR","message":"Failed to encode response"}}`)) //nolint:errcheck
	}
}

// getErrorCode 根据HTTP状态码获取错误码
func getErrorCode(statusCode int) string {
	switch statusCode {
	case http.StatusBadRequest:
		return "BAD_REQUEST"
	case http.StatusUnauthorized:
		return "UNAUTHORIZED"
	case http.StatusForbidden:
		return "FORBIDDEN"
	case http.StatusNotFound:
		return "NOT_FOUND"
	case http.StatusMethodNotAllowed:
		return "METHOD_NOT_ALLOWED"
	case http.StatusConflict:
		return "CONFLICT"
	case http.StatusRequestEntityTooLarge:
		return "REQUEST_TOO_LARGE"
	case http.StatusUnsupportedMediaType:
		return "UNSUPPORTED_MEDIA_TYPE"
	case http.StatusUnprocessableEntity:
		return "UNPROCESSABLE_ENTITY"
	case http.StatusTooManyRequests:
		return "TOO_MANY_REQUESTS"
	case http.StatusInternalServerError:
		return "INTERNAL_SERVER_ERROR"
	case http.StatusBadGateway:
		return "BAD_GATEWAY"
	case http.StatusServiceUnavailable:
		return "SERVICE_UNAVAILABLE"
	case http.StatusGatewayTimeout:
		return "GATEWAY_TIMEOUT"
	default:
		return "UNKNOWN_ERROR"
	}
}

// FileResponse 文件响应
func FileResponse(w http.ResponseWriter, filename string, contentType string, data []byte) {
	w.Header().Set("Content-Type", contentType)
	w.Header().Set("Content-Disposition", fmt.Sprintf("attachment; filename=\"%s\"", filename))
	w.Header().Set("Content-Length", fmt.Sprintf("%d", len(data)))
	w.WriteHeader(http.StatusOK)
	w.Write(data) //nolint:errcheck
}

// StreamResponse 流式响应
func StreamResponse(w http.ResponseWriter, contentType string) {
	w.Header().Set("Content-Type", contentType)
	w.Header().Set("Cache-Control", "no-cache")
	w.Header().Set("Connection", "keep-alive")
	w.WriteHeader(http.StatusOK)

	// 刷新响应头
	if flusher, ok := w.(http.Flusher); ok {
		flusher.Flush()
	}
}

// RedirectResponse 重定向响应
func RedirectResponse(w http.ResponseWriter, r *http.Request, url string, permanent bool) {
	statusCode := http.StatusFound
	if permanent {
		statusCode = http.StatusMovedPermanently
	}
	http.Redirect(w, r, url, statusCode)
}

// HealthCheckResponse 健康检查响应
func HealthCheckResponse(w http.ResponseWriter, service string, status string, details map[string]interface{}) {
	response := map[string]interface{}{
		"service":   service,
		"status":    status,
		"timestamp": time.Now(),
	}

	if details != nil {
		response["details"] = details
	}

	statusCode := http.StatusOK
	if status != "healthy" {
		statusCode = http.StatusServiceUnavailable
	}

	writeJSON(w, statusCode, response)
}

// MetricsResponse 指标响应
func MetricsResponse(w http.ResponseWriter, metrics map[string]interface{}) {
	response := map[string]interface{}{
		"metrics":   metrics,
		"timestamp": time.Now(),
	}

	writeJSON(w, http.StatusOK, response)
}