import axios from "axios";

const axiosInstance = axios.create({
    baseURL: import.meta.env.VITE_API_BASE_URL
});


export async function httpGet<T>(url:string, params:any): Promise<T> {
    const result = await axiosInstance.get<T>(url, { params });
    return result.data;
}

export async function httpPost<T>(url:string, params:any): Promise<T> {
    const result = await axiosInstance.post<T>(url, params);
    return result.data;
}

export async function httpPatch<T>(url:string, params:any): Promise<T> {
    const result = await axiosInstance.patch<T>(url, params);
    return result.data;
}

export  async function httpDelete<T>(url:string, params:any): Promise<T> {
    const result = await axiosInstance.delete<T>(url, { params });
    return result.data;
}