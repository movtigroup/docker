FROM nginx:alpine

# Copy all shell scripts to the Nginx html directory
COPY *.sh /usr/share/nginx/html/

# Ensure docker.sh points to install.sh as requested
RUN cp /usr/share/nginx/html/install.sh /usr/share/nginx/html/docker.sh

# Expose port 80
EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
