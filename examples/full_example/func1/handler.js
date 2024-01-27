export function handle(event, context, callback) {
  console.log("Hello from func1!");
  return {
    statusCode: 200,
    body: "Hello from func1!",
  };
}
