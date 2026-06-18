FROM nginx:alpine

# Copy everything (filtered by .dockerignore) to the Nginx html directory
COPY . /usr/share/nginx/html/

# Expose port 80
EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
