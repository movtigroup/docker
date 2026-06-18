FROM nginx:alpine

# Copy all shell scripts to the Nginx html directory
COPY *.sh /usr/share/nginx/html/

# Expose port 80
EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
