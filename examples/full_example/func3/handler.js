export function handle(event, context, callback) {
  console.log("Hello from func3!");
  return {
    statusCode: 200,
    body: "Hello from func3!",
  };
}
